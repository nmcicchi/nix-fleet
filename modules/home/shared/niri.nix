{ pkgs, config, lib, ... }: {
  programs.niri = {
    enable = true;
    # use nixpkgs cache instead of compiling from source
    package = pkgs.niri;

    settings = {
      # --- Input Configuration ---
      input = {
        keyboard = {
          xkb.options = lib.mkDefault "caps:swapescape";
          numlock = true;
        };
        touchpad = {
          tap = true;
          natural-scroll = true;
        };
        focus-follows-mouse.max-scroll-amount = "10%";

        power-key-handling.enable = false;
      };


      # --- Layout Configuration ---
      layout = {
        gaps = 12;
        center-focused-column = "never";
        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
        default-column-width = { proportion = 0.5; };
        
          focus-ring = {
            width = 4;
          # active.color = "#e4a068";
          };
        
        # border.off = true;
        
        shadow = {
          softness = 30;
          spread = 5;
          offset = { x = 0; y = 5; };
          color = "#0007";
        };
      };

      # --- Cursor ---
      cursor = {
        theme = "Numix-Cursor";
        size = 28;
      };

      # --- Startup Processes ---
      spawn-at-startup = [
        { command = [ "noctalia-shell" ]; }
      ];

      hotkey-overlay.skip-at-startup = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # --- Window Rules ---
      window-rules = [
        {
          draw-border-with-background = false;
        }
        {
          matches = [ { app-id = "firefox$"; title = "^Picture-in-Picture$"; } ];
          open-floating = true;
        }
        {
          matches = [ {app-id = "file_chooser"; } ];
          open-floating = true;

          default-floating-position = {
            x = 0;
            y = 0;
            relative-to = "top-right";
          };

          default-column-width = { fixed = 1000; };
          default-window-height = { fixed = 650; };
        }
        {
          matches = [ {app-id = "zen-twilight"; } ];
          opacity = 0.90;
        }
      ];

      # --- Keybindings ---
      binds = {
        "Mod+Shift+Slash".action.show-hotkey-overlay = { };

        "Mod+Return" = {
          hotkey-overlay.title = "Open a Terminal: alacritty";
          action.spawn = [ "alacritty" ];
        };
        "Mod+Q" = {
          hotkey-overlay.title = "Open browser: Zen";
          action.spawn = [ "zen-twilight" ];
        };
        "Mod+E" = {
          hotkey-overlay.title = "Open file manager: Yazi";
          action.spawn = [ "sh" "-c" "alacritty -e yazi" ];
        };
        "Mod+Shift+E" = {
          hotkey-overlay.title = "Open task manager: Kairo";
          action.spawn = [ "sh" "-c" "alacritty -e kairo" ];
        };

        # Core Noctalia Binds
        "Mod+R" = lib.mkDefault {
          hotkey-overlay.title = "Open launcher";
          action.spawn = [ "sh" "-c" "noctalia-shell ipc call launcher toggle" ];
        };
        "Mod+S" = lib.mkDefault {
          hotkey-overlay.title = "Open control center";
          action.spawn = [ "sh" "-c" "noctalia-shell ipc call controlCenter toggle" ];
        };

        # Hardware / Media Mappings
        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0" ];
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-" ];
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" ];
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" ];
        };

        "XF86AudioPlay" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "playerctl play-pause" ];
        };
        "XF86AudioStop" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "playerctl stop" ];
        };
        "XF86AudioPrev" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "playerctl previous" ];
        };
        "XF86AudioNext" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "playerctl next" ];
        };

        "XF86MonBrightnessUp" = {
          allow-when-locked = true;
          action.spawn = [ "brightnessctl" "--class=backlight" "set" "+10%" ];
        };
        "XF86MonBrightnessDown" = {
          allow-when-locked = true;
          action.spawn = [ "brightnessctl" "--class=backlight" "set" "10%-" ];
        };

        "XF86PowerOff".action.spawn = [ "noctalia-shell" "ipc" "call" "lockScreen" "lock" ];

        # Mouse binds

        # Navigation & Focus
        "Mod+O" = {
          repeat = false;
          action.toggle-overview = { };
        };
        
        "Mod+Shift+C" = {
          repeat = false;
          action.close-window = { };
        };

        "Mod+H".action.focus-column-left = { };
        "Mod+J".action.focus-window-down = { };
        "Mod+K".action.focus-window-up = { };
        "Mod+L".action.focus-column-right = { };

        "Mod+Ctrl+H".action.move-column-left = { };
        "Mod+Ctrl+J".action.move-window-down = { };
        "Mod+Ctrl+K".action.move-window-up = { };
        "Mod+Ctrl+L".action.move-column-right = { };

        "Mod+Home".action.focus-column-first = { };
        "Mod+End".action.focus-column-last = { };
        "Mod+Ctrl+Home".action.move-column-to-first = { };
        "Mod+Ctrl+End".action.move-column-to-last = { };

        "Mod+Shift+Left".action.focus-monitor-left = { };
        "Mod+Shift+Down".action.focus-monitor-down = { };
        "Mod+Shift+Up".action.focus-monitor-up = { };
        "Mod+Shift+Right".action.focus-monitor-right = { };
        "Mod+Shift+H".action.focus-monitor-left = { };
        "Mod+Shift+J".action.focus-monitor-down = { };
        "Mod+Shift+K".action.focus-monitor-up = { };
        "Mod+Shift+L".action.focus-monitor-right = { };

        "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
        "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
        "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
        "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };

        "Mod+U".action.focus-workspace-down = { };
        "Mod+I".action.focus-workspace-up = { };
        "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
        "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

        "Mod+Shift+Page_Down".action.move-workspace-down = { };
        "Mod+Shift+Page_Up".action.move-workspace-up = { };
        "Mod+Shift+U".action.move-workspace-down = { };
        "Mod+Shift+I".action.move-workspace-up = { };

        # Mouse & Wheel Bindings
        "Mod+WheelScrollDown" = { cooldown-ms = 150; action.focus-workspace-down = { }; };
        "Mod+WheelScrollUp" = { cooldown-ms = 150; action.focus-workspace-up = { }; };
        "Mod+Ctrl+WheelScrollDown" = { cooldown-ms = 150; action.move-column-to-workspace-down = { }; };
       "Mod+Ctrl+WheelScrollUp" = { cooldown-ms = 150; action.move-column-to-workspace-up = { }; };

        "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
        "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
        "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
        "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

        # Workspace Contexts
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;
        
        "Mod+Ctrl+1".action.move-column-to-workspace = 1;
        "Mod+Ctrl+2".action.move-column-to-workspace = 2;
        "Mod+Ctrl+3".action.move-column-to-workspace = 3;
        "Mod+Ctrl+4".action.move-column-to-workspace = 4;
        "Mod+Ctrl+5".action.move-column-to-workspace = 5;
        "Mod+Ctrl+6".action.move-column-to-workspace = 6;
        "Mod+Ctrl+7".action.move-column-to-workspace = 7;
        "Mod+Ctrl+8".action.move-column-to-workspace = 8;
        "Mod+Ctrl+9".action.move-column-to-workspace = 9;

        # Column Manipulation
        "Mod+BracketLeft".action.consume-or-expel-window-left = { };
        "Mod+BracketRight".action.consume-or-expel-window-right = { };
        "Mod+Comma".action.consume-window-into-column = { };
        "Mod+Period".action.expel-window-from-column = { };

        "Mod+D".action.switch-preset-column-width = { };
        "Mod+Shift+R".action.switch-preset-window-height = { };
        "Mod+Ctrl+R".action.reset-window-height = { };
        "Mod+F".action.maximize-column = { };
        "Mod+Shift+F".action.fullscreen-window = { };
        "Mod+Ctrl+F".action.expand-column-to-available-width = { };
        "Mod+C".action.center-column = { };
        "Mod+Ctrl+C".action.center-visible-columns = { };

        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";
        "Mod+Shift+Minus".action.set-window-height = "-10%";
        "Mod+Shift+Equal".action.set-window-height = "+10%";

        "Mod+V".action.toggle-window-floating = { };
        "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };
        "Mod+W".action.toggle-column-tabbed-display = { };

        # Screen Capture & Escapes
        "Print".action.screenshot = { };
        "Mod+P".action.screenshot = { };
        "Ctrl+Print".action.screenshot-screen = { };
        "Alt+Print".action.screenshot-window = { };

        "Mod+Escape" = {
          allow-inhibiting = false;
          action.toggle-keyboard-shortcuts-inhibit = { };
        };
        
        "Mod+Shift+P".action.power-off-monitors = { };
      };
    };
  };

  xdg.configFile = {
    "niri/full-config.kdl".text = ''
      include "${config.home.homeDirectory}/.config/niri/config.kdl"
      include "${config.home.homeDirectory}/.config/niri/noctalia.kdl"
      include optional = true "${config.home.homeDirectory}/.config/niri/monitors.kdl"
    '';
  };

  home.sessionVariables.NIRI_CONFIG =
    "${config.home.homeDirectory}/.config/niri/full-config.kdl";

  systemd.user.sessionVariables.NIRI_CONFIG =
  "${config.home.homeDirectory}/.config/niri/full-config.kdl";

  # Create monitors.kdl for monique
  home.activation.niriMonitorsFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.config/niri"
    if [ ! -e "${config.home.homeDirectory}/.config/niri/monitors.kdl" ]; then
      $DRY_RUN_CMD touch "${config.home.homeDirectory}/.config/niri/monitors.kdl"
    fi
  '';
} 
