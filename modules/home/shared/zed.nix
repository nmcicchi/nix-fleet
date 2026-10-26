{ pkgs, ... }: {
  programs.zed-editor = {
    enable = true;

    package = pkgs.unstable.zed-editor;

    userSettings = {
      vim_mode = true;

      assistant = {
        enabled = false;
      };

      terminal = {
        detect_venv = {
          on = {
            directories = [ ".env" "env" ".venv" "venv" ];
            activate_script = "default";
          };
        };
        env = {
          TERM = "alacritty";
        };
        font_family = "FiraCode Nerd Font";
        font_features = null;
        font_size = null;
        line_height = "comfortable";
        option_as_meta = false;
        button = false;
        shell = "system";
        toolbar = {
          title = true;
        };
        working_directory = "current_project_directory";
      };

      tab_size = 2;
      hard_tabs = false;

      format_on_save = "on";

      show_whitespaces = "all";
      buffer_font_size = 14.0;
      ui_font_size = 15;

      theme = {
        mode = "dark";
        dark = "One Dark";
        light = "One Light";
      };

      lsp = {
        nix = {
          binary = {
            path = "${pkgs.nil}/bin/nil";
          };
        };
      };

      telemetry = {
        metrics = false;
        diagnostics = false;
      };

      load_direnv = "shell_hook";
      base_keymap = "VSCode";
    };

    userKeymaps = [
      {
        context = "Editor && vim_mode == normal";
        bindings = {
          "space f f" = "file_finder::Toggle";
          "space e" = "project_panel::ToggleFocus";
        };
      }
    ];    

    extensions = [
      "nix"
      "markdown"
    ];
  };
}
