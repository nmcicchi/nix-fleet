{
  pkgs,
  ...
}: {
  vim = {

    theme = {
      enable = true;
      name = "base16";
      base16-colors = {
        base00 = "#1f1c19"; # bg slightly lighter
        base01 = "#292521"; # surface
        base02 = "#3a342f"; # selection / borders
        base03 = "#b0aaa2"; # comments/subtext softer
        base04 = "#dcd6d0"; # dark text
        base05 = "#dcd6d0"; # default text softer
        base06 = "#f5f1ed"; # light text
        base07 = "#ffffff"; # lightest
        base08 = "#ac4935"; # danger softer
        base09 = "#cc6f3c"; # amber softer
        base0A = "#d9b172"; # highlight / optional
        base0B = "#8fa88f"; # sage softer
        base0C = "#7bb5a7"; # cyan accent
        base0D = "#6b8fa3"; # blue / optional
        base0E = "#a77aa0"; # purple / keywords
        base0F = "#3a342f"; # subtle brown / borders
      };
    };

    visuals = {
      nvim-scrollbar.enable = false;
      nvim-web-devicons.enable = true;
      cinnamon-nvim.enable = true;
      nvim-cursorline.enable = true;
      fidget-nvim.enable = true;

      highlight-undo.enable = true;
      indent-blankline.enable = true;
    };

    treesitter = {
      enable = true;
      context.enable = true;
      autotagHtml = true;
      indent.enable = true;
      highlight.enable = true;
      addDefaultGrammars = true;
    };

    statusline = {
      lualine = {
        enable = true;
        setupOpts.options.theme = "base16";
      };
    };

    spellcheck = {
      enable = true;
      languages = ["en"];
    };

    clipboard.enable = true;
    clipboard.providers.wl-copy.enable = true;

    lsp = {
      enable = true;
      formatOnSave = false;
      lightbulb.enable = true;
      trouble.enable = true;
      nvim-docs-view.enable = true;
      presets.harper.enable = true; # actual lsp
      otter-nvim.enable = true; # actual lsp
    };

  #nix, python, java, lua, javascript, html, css, 
  #sql, bash, markdown, yaml, json 
    languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;
            
        nix.enable = true;
        lua.enable = true;
        python.enable = true;
        java.enable = true;
        typescript.enable = true;
        html.enable = true;
        css.enable = true;
        sql.enable = true;
        bash.enable = true;
        yaml.enable = true;
        json.enable = true;

        markdown = {
          enable = true;
          extensions.render-markdown-nvim = {
            enable = true;
            setupOpts = {
              # Render dynamically on load
              enabled = true;

              # reveal raw syntax when cursor sits on the line
              anti_conceal.enabled = true;

              checkbox = {
                enabled = true;
              };
              
              heading = { enabled = true; };
              code = { enabled = true; };
              bullet = { enabled = true; };
            };
          };
        };
    };

    autopairs.nvim-autopairs.enable = true; # Autobrackets

    # Autocomplete
    autocomplete = {
      blink-cmp = {
        enable = true;
        friendly-snippets.enable = true;
        sourcePlugins.emoji.enable = true;
      };
    };

    # Debugging code
    debugger = {
      nvim-dap = {
        enable = true;
        ui.enable = true;
      };
    };


    snippets.luasnip.enable = false;

    filetree.neo-tree.enable = true; # Filetree

    tabline.nvimBufferline.enable = true;

    telescope = {
        enable = true;
        extensions = [
          {
            name = "fzf";
            packages = [pkgs.vimPlugins.telescope-fzf-native-nvim];
            setup = {fzf = {fuzzy = true;};};
          }
        ];
    };

    binds = {
      whichKey.enable = true;
      cheatsheet.enable = true;
    };

    git = {
      enable = true;
      gitsigns.enable = true;
      neogit.enable = true;
    };

    dashboard.alpha.enable = true;

    notify.nvim-notify.enable = true;

    projects.project-nvim.enable = true;

    utility = {
      diffview-nvim.enable = true;
      surround.enable = true;
      multicursors.enable = false;
      smart-splits.enable = true;
      undotree.enable = true; # use with :undotree
      motion.precognition.enable = false; # shows hints for navigation

      images = {
        image-nvim.enable = false;
        img-clip.enable = false;
      };
    };

    terminal.toggleterm.enable = true;

    ui = {
      borders.enable = true;
      noice.enable = true;
      colorizer.enable = true;
      illuminate.enable = true;
    };

    comments.comment-nvim = {
      enable = true;
      setupOpts.mappings.basic = true;
    };

    options = {
      # Indents
      tabstop = 2;
      softtabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      autoindent = true;
      smartindent = true;
      breakindent = true;

      # Splitting
      splitbelow = false;
      splitright = false;

      # Undo
      undofile = true;
      undolevels = 10000;
      swapfile = false;
      backup = true;

      conceallevel = 2;
      concealcursor = "nc";
    };

    lazy.enable = false;

    extraLuaFiles = [ ./filetypes.lua ];
  };
}
