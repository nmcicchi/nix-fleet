# ts dont work at all at all
{ pkgs, lib, fleetSettings, ... }: {
  system.activationScripts.pullOciUpdates = {
    text = ''
      # Dynamically generated list of all users defined under sequoia.users
      USERS=(${lib.concatStringsSep " " (builtins.attrNames fleetSettings.sequoia.users)})

      for target_user in "''${USERS[@]}"; do
        if id -u "$target_user" &>/dev/null; then
          user_uid=$(id -u "$target_user")
          export XDG_RUNTIME_DIR="/run/user/$user_uid"

          echo "==> Checking container images for $target_user..."
          
          # Find all unique images used by this user's containers
          images=$(sudo -u "$target_user" ${pkgs.podman}/bin/podman ps -a --format "{{.Image}}" 2>/dev/null || true)

          if [ -n "$images" ]; then
            for img in $images; do
              echo "Pulling latest for: $img"
              sudo -u "$target_user" ${pkgs.podman}/bin/podman pull "$img"
            done

            echo "==> Restarting container services for $target_user..."
            services=$(sudo -u "$target_user" ${pkgs.systemd}/bin/systemctl --user list-units --type=service --no-legend 'podman-*' 2>/dev/null | awk '{print $1}')
            
            for srv in $services; do
              echo "Restarting service: $srv"
              sudo -u "$target_user" ${pkgs.systemd}/bin/systemctl --user restart "$srv"
            done
          fi
        fi
      done
    '';
  };
}
