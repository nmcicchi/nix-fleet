#!/usr/bin/env bash
# Usage: scripts/gen-certs.sh [domain ...]
#
# Generates (or reuses) a local CA and issues one server certificate covering
# all given domains. Defaults to the domains enabled in my.reverseProxy on
# $SERVER_HOST (sequoia).
#
# Outputs:
#   certs/ca.pem           public CA cert (plaintext, committed, trusted by clients)
#   secrets/CA.yaml     sops, nic-only: holds `ca-key` (merged in, other secrets untouched)
#   secrets/certs.yaml     sops, nic + sequoia: `server-cert` and `server-key`
#
# Run with:
#   nix-shell -p openssl sops jq git --run 'bash scripts/gen-certs.sh'
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
umask 077

SERVER_HOST="${SERVER_HOST:-sequoia}"
CA_YAML=secrets/tower.yaml
CERTS_YAML=secrets/certs.yaml
CA_PEM=certs/ca.pem

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- Domains: from args, or from the server's enabled vhosts ---
domains=("$@")
if [ "${#domains[@]}" -eq 0 ]; then
  mapfile -t domains < <(
    nix eval --json ".#nixosConfigurations.${SERVER_HOST}.config.my.reverseProxy.vhosts" \
      --apply 'vs: map (v: v.domain) (builtins.filter (v: v.enable) (builtins.attrValues vs))' \
      | jq -r '.[]'
  )
fi
[ "${#domains[@]}" -gt 0 ] || { echo "no domains found (pass them as arguments)" >&2; exit 1; }
echo "Domains: ${domains[*]}"

# --- Helpers ---
# Render a file as a yaml block scalar under the given key.
block() { echo "$1: |"; sed 's/^/  /' "$2"; }

# Encrypt a plaintext yaml to a repo path; the path is used to match .sops.yaml rules.
encrypt() {
  sops --encrypt --filename-override "$1" --input-type yaml --output-type yaml "$2" > "$1.tmp"
  mv "$1.tmp" "$1"
}

# --- CA: reuse if it exists, otherwise create ---
if [ -f "$CA_PEM" ]; then
  # CA already exists: its key must be readable, otherwise stop rather than
  # silently making a new CA (which would break trust on every client).
  sops -d --extract '["ca-key"]' "$CA_YAML" > "$tmp/ca.key" || {
    echo "$CA_PEM exists but ca-key can't be read from $CA_YAML" >&2
    exit 1
  }
  cp "$CA_PEM" "$tmp/ca.pem"
else
  echo "Creating new CA"
  openssl ecparam -name prime256v1 -genkey -noout -out "$tmp/ca.key"
  openssl req -x509 -new -key "$tmp/ca.key" -sha256 -days 3650 \
    -subj "/CN=Home Lab CA" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -out "$tmp/ca.pem"
  mkdir -p certs
  cp "$tmp/ca.pem" "$CA_PEM"

  if [ -f "$CA_YAML" ]; then
    # Add the key to the existing file without touching the other secrets (needs sops >= 3.8)
    sops set "$CA_YAML" '["ca-key"]' "$(jq -Rs . "$tmp/ca.key")"
  else
    block ca-key "$tmp/ca.key" > "$tmp/CA.yaml"
    encrypt "$CA_YAML" "$tmp/tower.yaml"
  fi
fi

# --- Server certificate covering all domains ---
san="$(printf 'DNS:%s,' "${domains[@]}")"
san="${san%,}"

openssl ecparam -name prime256v1 -genkey -noout -out "$tmp/server.key"
openssl req -new -key "$tmp/server.key" -subj "/CN=${domains[0]}" -out "$tmp/server.csr"

cat > "$tmp/ext.cnf" <<EOF
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=$san
EOF

openssl x509 -req -in "$tmp/server.csr" \
  -CA "$tmp/ca.pem" -CAkey "$tmp/ca.key" -CAcreateserial \
  -out "$tmp/server.crt" -days 825 -sha256 -extfile "$tmp/ext.cnf"

{
  block server-cert "$tmp/server.crt"
  block server-key "$tmp/server.key"
} > "$tmp/certs.yaml"
encrypt "$CERTS_YAML" "$tmp/certs.yaml"

echo
echo "Done. Next:"
echo "  git add .sops.yaml certs secrets scripts"
echo "  rebuild sequoia, then lotus and cedar"
echo "Server cert is valid for 825 days; re-run this script before then."
