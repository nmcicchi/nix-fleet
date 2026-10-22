{ pkgs, ... }: {
  programs.zed-editor = {
    enable = true;

    package = pkgs.unstable.zed;

    userSettings = {
      vim_mode = true;

      tab_size = 2;
      hard_tabs = false;

      format_on_save = "on";

      # Typography scaling
      buffer_font_size = 14.0;
      ui_font_size = 15;

      theme = {
        mode = "dark";
        dark = "One Dark";
        light = "One Light";
      };

      telemetry = {
        metrics = false;
        diagnostics = false;
      };
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
      #  "toml"
      #  "html"
      #  "css"
      #  "json"
      #  "yaml"
      #  "python"
      #  "java"
      "markdown"
    ];
  };

  xdg.configFile."zed/themes/base16-custom.json".text = builtins.toJSON {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
    name = "Base16 Custom";
    author = "Nic";
  };
}
