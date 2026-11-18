{ pkgs, ... }:
let
  leader = "alt";
in
{
  programs.zed-editor = {
    enable = true;
    package = pkgs.unstable.zed-editor;

    mutableUserKeymaps = false;
    #mutableUserSettings = true;

    extraPackages = with pkgs; [
      nil
      nixd
      nixfmt
    ];

    userSettings = {
      vim_mode = true;

      show_edit_predictions = false;
      edit_predictions = {
        provider = "none";
      };

      # Agent Panel
      disable_ai = true;
      agent = {
        default_profile = "ask"; # Read-only mode by default for discussion/debugging
        default_model = {
          provider = "anthropic";
          model = "claude-sonnet-4-5";
        };
        tool_permissions = {
          default = "confirm"; # Always ask before editing files or running commands
        };
      };

      language_models = {
        anthropic = {
          api_url = "https://api.anthropic.com";
        };
        google = {
          api_url = "https://generativelanguage.googleapis.com";
        };
      };

      terminal = {
        detect_venv = {
          on = {
            directories = [
              ".env"
              "env"
              ".venv"
              "venv"
            ];
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

      telemetry = {
        metrics = false;
        diagnostics = false;
      };

      load_direnv = "shell_hook";

      base_keymap = "Zed";
    };

    userKeymaps = [
      {
        # Global toggles that work everywhere
        context = "Workspace || Dock || Pane || Editor || Terminal";
        bindings = {
          # Layer 1: focus a specific panel (toggle back to editor if already focused)
          "${leader}-e" = "project_panel::ToggleFocus";
          "${leader}-t" = "terminal_panel::ToggleFocus";
          "${leader}-a" = "agent::ToggleFocus";
          "${leader}-d" = "debug_panel::ToggleFocus";
          "${leader}-g" = "git_panel::ToggleFocus";
          "${leader}-o" = "outline_panel::ToggleFocus";

          # Layer 2: show/hide an entire dock
          "${leader}-1" = "workspace::ToggleLeftDock";
          "${leader}-2" = "workspace::ToggleBottomDock";
          "${leader}-3" = "workspace::ToggleRightDock";

          # Pane navigation (unchanged)
          "${leader}-h" = "workspace::ActivatePaneLeft";
          "${leader}-j" = "workspace::ActivatePaneDown";
          "${leader}-k" = "workspace::ActivatePaneUp";
          "${leader}-l" = "workspace::ActivatePaneRight";
        };
      }
      {
        context = "Editor && vim_mode == normal";
        bindings = {
          "${leader}-f f" = "file_finder::Toggle";
        };
      }
      {
        # Works anywhere inside the Agent Panel, including the prompt box
        context = "AgentPanel || (MessageEditor > Editor)";
        bindings = {
          "${leader}-m" = "agent::ToggleModelSelector";
          "${leader}-n" = "agent::CycleFavoriteModels";
          "${leader}-p" = "agent::ToggleProfileSelector";
        };
      }
      {
        # not_editing so h/l/enter don't fire while renaming a file
        context = "ProjectPanel && not_editing";
        bindings = {
          "enter" = "project_panel::Open";
          "l" = "project_panel::Open";
          "h" = "project_panel::CollapseSelectedEntry";
        };
      }
      {
        context = "Terminal";
        bindings = {
          "${leader}-s" = "pane::SplitRight";
          "${leader}-]" = "pane::ActivateNextItem";
          "${leader}-[" = "pane::ActivatePreviousItem";
        };
      }
    ];

    extensions = [
      "nix"
      "markdown"
    ];
  };
}
