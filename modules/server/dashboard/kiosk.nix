{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    cage
    chromium
  ];

  hardware.graphics.enable = true;

  systemd.defaultUnit = "graphical.target";

  users.users.nic.extraGroups = [ "video" "input" "render" "seat" ];

  security.polkit.enable = true;
  services.seatd.enable = true;
 
  programs.chromium = {
    enable = true;
  };

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
      StandardOutput = "journal";
      StandardError = "journal";

      RuntimeDirectory = "ha-kiosk";
      Environment = [
        "XDG_RUNTIME_DIR=/run/ha-kiosk"
        "WLR_LIBINPUT_NO_DEVICES=1"
        "WLR_NO_HARDWARE_CURSORS=1" # Prevents wlroots from crashing on Pi DRM planes
      ];

      ExecStart = ''
        ${pkgs.cage}/bin/cage -d -- ${pkgs.chromium}/bin/chromium \
          --enable-features=UseOzonePlatform \
          --ozone-platform=wayland \
          --user-data-dir=/run/ha-kiosk/chromium-profile \
          --kiosk \
          --no-first-run \
          --disable-pinch \
          --overscroll-history-navigation=0 \
          "http://homeassistant.home/kiosk-dashboard/"
      '';

      Restart = "always";
      RestartSec = "5s";
    };
  };
}
