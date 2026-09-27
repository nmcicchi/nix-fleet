{ pkgs, ... }: {
  # Systemd services for controlling screen power
  systemd = {
    services = {
      display-off = {
        description = "Turn off dashboard screen";
        serviceConfig = {
          Type = "oneshot";
          # Turns off the display using the sysfs backlight/graphics interface
          ExecStart = pkgs.writeShellScript "display-off" ''
            # Try turning off via vc4 DRM (Raspberry Pi specific)
            echo 4 > /sys/class/graphics/fb0/blank 2>/dev/null || true
            
            # Alternatively, turn off the backlight if it's a touchscreen
            if [ -f /sys/class/backlight/rpi_backlight/bl_power ]; then
              echo 1 > /sys/class/backlight/rpi_backlight/bl_power
            fi
          '';
        };
      };

      display-on = {
        description = "Turn on dashboard screen";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "display-on" ''
            echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null || true
            
            if [ -f /sys/class/backlight/rpi_backlight/bl_power ]; then
              echo 0 > /sys/class/backlight/rpi_backlight/bl_power
            fi
          '';
        };
      };
    };
  };
}
