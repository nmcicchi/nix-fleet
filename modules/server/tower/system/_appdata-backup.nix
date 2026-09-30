{ config, lib, pkgs, ... }:

with lib;

let
  driveUuid = "2867abdf-830d-465c-9104-c14a77a7056d";
  mountTarget = "/mnt/external_backup";
  appdataDir = "/appdata";

  # Number of archives to keep per /appdata subdirectory
  keepBackups = 7;

  # Anything else that writes to /appdata and should be stopped during the
  # backup (e.g. a native NixOS service). oci-containers are detected automatically.
  extraStopUnits = [ ];

  ociCfg = config.virtualisation.oci-containers;

  # Only containers with a bind mount under /appdata need to be stopped.
  # This skips the tailscale sidecar (its state lives in /var/lib) and never
  # touches podman-lan-bridge.service, since that isn't an oci-container.
  containersUsingAppdata = filterAttrs
    (_name: container: any (v: hasPrefix "${appdataDir}/" v) container.volumes)
    ociCfg.containers;

  stopUnits =
    (map (name: "${ociCfg.backend}-${name}.service") (attrNames containersUsingAppdata))
    ++ extraStopUnits;
in
{
  systemd = {
    services.appdata-backup = {
      description = "Back up /appdata to the external drive";

      path = [
        pkgs.util-linux # mount, umount, mountpoint
        pkgs.gnutar
        pkgs.gzip
        pkgs.systemd
        pkgs.coreutils
        pkgs.findutils # xargs
      ];

      script = ''
        set -euo pipefail

        DRIVE_UUID="${driveUuid}"
        MOUNT_TARGET="${mountTarget}"
        SOURCE_DIR="${appdataDir}"
        KEEP=${toString keepBackups}
        UNITS="${concatStringsSep " " stopUnits}"

        WE_MOUNTED=0
        STOPPED=()
        FAILED=()

        # Runs on every exit path (success, error, signal): bring services back
        # up and unmount the drive if we were the ones who mounted it.
        cleanup() {
          echo "Running cleanup..."
          if [ "''${#STOPPED[@]}" -gt 0 ]; then
            echo "Restarting: ''${STOPPED[*]}"
            systemctl start "''${STOPPED[@]}" || echo "Warning: failed to restart some units"
          fi
          cd /
          if [ "$WE_MOUNTED" -eq 1 ]; then
            umount "$MOUNT_TARGET" || echo "Warning: could not unmount $MOUNT_TARGET"
          fi
        }
        trap cleanup EXIT

        mkdir -p "$MOUNT_TARGET"
        if mountpoint -q "$MOUNT_TARGET"; then
          echo "Backup drive already mounted, will leave it mounted."
        else
          echo "Mounting backup drive..."
          mount -U "$DRIVE_UUID" "$MOUNT_TARGET"
          WE_MOUNTED=1
        fi

        # Only stop (and later restart) units that are actually running now
        for unit in $UNITS; do
          if systemctl is-active --quiet "$unit"; then
            STOPPED+=("$unit")
          fi
        done

        if [ "''${#STOPPED[@]}" -gt 0 ]; then
          echo "Stopping: ''${STOPPED[*]}"
          systemctl stop "''${STOPPED[@]}"
        else
          echo "No matching units running, backing up anyway."
        fi

        for dir in "$SOURCE_DIR"/*/; do
          [ -d "$dir" ] || continue

          name=$(basename "$dir")
          [ "$name" = "lost+found" ] && continue

          target="$MOUNT_TARGET/$name"
          mkdir -p "$target"

          final="$target/$name-$(date +%Y%m%d_%H%M%S).tar.gz"
          partial="$final.partial"

          echo "Archiving $name..."
          if tar -czf "$partial" -C "$dir" .; then
            # Only a complete archive ever gets the real name
            mv "$partial" "$final"

            # Retention: drop everything past the newest $KEEP archives
            ls -1t "$target"/"$name"-*.tar.gz 2>/dev/null \
              | tail -n +$((KEEP + 1)) \
              | xargs -r rm -f -- || true
          else
            echo "ERROR: archiving $name failed"
            rm -f "$partial"
            FAILED+=("$name")
          fi
        done

        if [ "''${#FAILED[@]}" -gt 0 ]; then
          echo "Backup finished WITH FAILURES: ''${FAILED[*]}"
          exit 1
        fi

        echo "Backup finished successfully."
      '';

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

    timers.appdata-backup = {
      description = "Nightly /appdata backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 02:00:00";
        # Run at boot if the machine was off at 2am
        Persistent = true;
      };
    };
  };
}
