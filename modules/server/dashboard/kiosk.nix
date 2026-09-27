{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    cage
    chromium
  ];

  hardware.graphics.enable = true;

  systemd.services.ha-kiosk = {
    description = "Home Assistant Kiosk Display";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "systemd-user-sessions.service" ];
    wantedBy = [ "graphical.target" ];

    serviceConfig = {
      Type = "simple";
      User = "nic";
      PAMName = "login";
      TTYPath = "/dev/tty7";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      StandardInput = "tty";
      StandardOutput = "tty";

      # Target the specific HA kiosk view with native Wayland flags
      ExecStart = ''
        ${pkgs.cage}/bin/cage -d -- ${pkgs.chromium}/bin/chromium \
          --enable-features=UseOzonePlatform \
          --ozone-platform=wayland \
          --kiosk \
          --no-first-run \
          --incognito \
          --disable-pinch \
          --overscroll-history-navigation=0 \
          "http://homeassistant.home/kiosk-dashboard/"
      '';

      Restart = "always";
      RestartSec = "5s";
    };
  };
}
