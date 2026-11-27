{ pkgs, ... }:
let
  notifyWrapper = pkgs.writeShellScript "matrix-ntfy-notify" ''
    # Suppress if Fractal is already open on this machine
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

  xdg.configFile."ntfy/client.yml".text = ''
    default-host: https://ntfy.home
    subscribe:
      - topic: up_matrix_shared_9f8a7b6c
        command: "${notifyWrapper}"
  '';

  systemd.user.services.ntfy-matrix-push = {
    Unit = {
      Description = "Matrix push notification subscriber via ntfy";
      After = [ "network-online.target" ];
    };
    Service = {
      # Uses the sops-nix secret decrypted on the NixOS host
      EnvironmentFile = "/run/secrets/ntfy-client-env";
      ExecStart = "${pkgs.ntfy-sh}/bin/ntfy subscribe --from-config";
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
