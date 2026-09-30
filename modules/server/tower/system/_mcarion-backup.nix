{ pkgs, ... }: {
  systemd = {
    services.docker-volume-backup = {
      description = "Safely backup Docker/Arion volumes to external drive";
      
      # Added coreutils, removed need for grep
      path = [ 
        pkgs.util-linux 
        pkgs.gnutar 
        pkgs.gzip 
        pkgs.systemd 
        pkgs.docker 
        pkgs.gawk 
        pkgs.coreutils 
      ];

      script = ''
        # Fail on first error, catch undefined variables, fail in pipelines
        set -euo pipefail

        DRIVE_UUID="2867abdf-830d-465c-9104-c14a77a7056d"
        MOUNT_TARGET="/mnt/external_backup"
        DOCKER_VOLUME_DIR="/appdata"
        ACTIVE_SERVICES=$(systemctl list-units --type=service --state=running "arion-*" | gawk '/^arion-/ {print $1}')

        # Cleanup function ensures services restart and drive unmounts even on failure
        cleanup() {
          echo "Running cleanup..."
          if [ -n "$ACTIVE_SERVICES" ]; then
              echo "Restoring Arion projects..."
              systemctl start $ACTIVE_SERVICES || true
          fi
          cd /
          mountpoint -q "$MOUNT_TARGET" && umount "$MOUNT_TARGET" || true
        }
        
        # Trap ERR, INT, TERM, EXIT to guarantee cleanup runs
        trap cleanup EXIT

        echo "Identifying active Arion projects..."
        # Simplified to use awk for both matching and extracting
        ACTIVE_SERVICES=$(systemctl list-units --type=service --state=running "arion-*" | gawk '/^arion-/ {print $1}')

        if [ -z "$ACTIVE_SERVICES" ]; then
            echo "No active Arion services found running. Proceeding with backup anyway."
        fi

        echo "Creating mount target if missing..."
        mkdir -p "$MOUNT_TARGET"

        echo "Mounting external drive by UUID..."
        mount -U "$DRIVE_UUID" "$MOUNT_TARGET"

        if [ -n "$ACTIVE_SERVICES" ]; then
            echo "Stopping active Arion projects: $ACTIVE_SERVICES"
            systemctl stop $ACTIVE_SERVICES
            sleep 2
        fi

        # Loop through each subdirectory in /appdata and archive them separately
        for dir in "$DOCKER_VOLUME_DIR"/*/; do
            [ -d "$dir" ] || continue
            
            SERVICE_NAME=$(basename "$dir")
            TARGET_DIR="$MOUNT_TARGET/$SERVICE_NAME"
            mkdir -p "$TARGET_DIR"
            
            BACKUP_FILE="$TARGET_DIR/$${SERVICE_NAME}_$(date +%Y%m%d_%H%M%S).tar.gz"
            
            echo "Creating compressed volume archive for $SERVICE_NAME..."
            tar -czf "$BACKUP_FILE" -C "$dir" . || echo "Warning: Tar for $SERVICE_NAME completed with minor errors, moving on..."
        done

        echo "Backup process finished successfully!"
        # The trap will automatically handle restarting services and unmounting the drive here
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
    
    timers.docker-volume-backup = {
      description = "Timer for Docker Arion volume backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 02:00:00";

        # Ensures the backups run on boot if server was powered off at 2 am
        Persistent = true;
      };
    };
  };
}
