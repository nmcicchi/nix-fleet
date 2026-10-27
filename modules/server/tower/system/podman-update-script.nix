{ config, pkgs, lib, ... }:
let
  containers = lib.filterAttrs (_: c:
    c.podman.user != "root"
    && c.imageFile == null
    && (c.imageStream or null) == null
  ) config.virtualisation.oci-containers.containers;

  callFor = name: c: let
    u = config.users.users.${c.podman.user};
  in lib.concatStringsSep " " [
    "update"
    (lib.escapeShellArg c.podman.user)
    (lib.escapeShellArg u.home)
    (toString u.uid)
    (lib.escapeShellArg name)
    (lib.escapeShellArg c.image)
  ];
in {
  systemd.services.pull-oci-updates = {
    description = "Pull updated images and restart rootless oci-container units";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    # "/run/wrappers" -> /run/wrappers/bin (newuidmap/newgidmap for rootless podman)
    path = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.systemd
      config.virtualisation.podman.package
      "/run/wrappers"
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      update() {
        local user=$1 home=$2 uid=$3 name=$4 image=$5
        run() {
          runuser -u "$user" -- env HOME="$home" XDG_RUNTIME_DIR="/run/user/$uid" "$@"
        }

        echo "==> $user/$name: pulling $image"
        run podman pull -q "$image" >/dev/null || { echo "    pull failed"; return; }
        new=$(run podman image inspect --format '{{.Id}}' "$image") || return

        # Image the container is actually running (absent container => nothing to restart;
        # the next start uses the freshly pulled image anyway)
        cur=$(run podman inspect --format '{{.Image}}' "$name" 2>/dev/null) || return
        cur_id=$(run podman image inspect --format '{{.Id}}' "$cur" 2>/dev/null)

        if [ "$cur_id" != "$new" ]; then
          echo "    new image, restarting podman-$name.service"
          # try-restart: only restarts if already active, so units gated by
          # other logic (qbittorrent via the VPN watchdog) are never started here
          systemctl try-restart "podman-$name.service" || echo "    restart failed"
        else
          echo "    up to date"
        fi
      }

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList callFor containers)}
    '';
  };

  systemd.timers.pull-oci-updates = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
