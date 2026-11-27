{ pkgs, ... }:
let
  notifyWrapper = pkgs.writeShellScript "matrix-ntfy-notify" ''
    # Skip if Fractal is already running to prevent duplicate alerts
    if ${pkgs.procps}/bin/pgrep -x fractal >/dev/null; then
      exit 0
    fi

    title="''${NTFY_TITLE:-Matrix}"
    body="''${NTFY_MESSAGE:-New notification}"
    ${pkgs.libnotify}/bin/notify-send -a "Matrix" "$title" "$body"
  '';
in
{
  home.packages = with pkgs; [
    ntfy-sh
    libnotify
  ];

  # Place your token file via sops-nix and reference its path here
  xdg.configFile."ntfy/client.yml".text = ''
    default-host: https://ntfy.yourdomain.com
    subscribe:
      - topic: up_matrix_laptop_9f8a7b6c
        command: "${notifyWrapper}"
  '';

  systemd.user.services.ntfy-matrix-push = {
    Unit = {
      Description = "Matrix push notification subscriber via ntfy";
      After = [ "network-online.target" ];
    };
    Service = {
      # If using token auth, pass NTFY_TOKEN via EnvironmentFile from sops-nix
      ExecStart = "${pkgs.ntfy-sh}/bin/ntfy subscribe --from-config";
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
