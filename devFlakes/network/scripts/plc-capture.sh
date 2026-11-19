#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: plc-capture <ssh-target> [interface] [bpf-filter]

Examples:
  plc-capture sequoia plc-br
  plc-capture nic@192.168.1.50 plc-br "tcp port 44818"
EOF
  exit 1
}

[[ $# -lt 1 ]] && usage

SSH_TARGET="$1"
IFACE="${2:-plc-br}"
BPF_FILTER="${3:-port 44818 or port 2222}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSLATOR="${SCRIPT_DIR}/enip_summary.py"

# -T: disable pseudo-TTY allocation so stdout stays clean binary pcap data
# -o BatchMode=yes: fail fast instead of hanging on interactive prompts
ssh -T -o BatchMode=yes "${SSH_TARGET}" \
  "sudo tcpdump -i $(printf '%q' "${IFACE}") -nn -s 0 -U -w - $(printf '%q' "${BPF_FILTER}")" \
  | tshark -r - -l -T fields \
      -e frame.time_epoch \
      -e ip.src \
      -e ip.dst \
      -e enip.command \
      -e enip.session \
      -e enip.status \
      -e cip.service \
      -e cip.ioi.path \
      -E separator=$'\t' \
      -E occurrence=f \
  | python3 "${TRANSLATOR}"
