{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    
    profiles.default = {
      # Base extensions you want across ALL projects
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        mkhl.direnv
      ];

      # Global Vim & Editor Preferences
      userSettings = {
        "vim.enable" = true;
        "vim.useSystemClipboard" = true;
        "vim.leader" = "<space>";
        # This requires the extension
        "workbench.colorTheme" = "Mac Dark Pro";
        "direnv.status.show" = "warning";
        "keyboard.dispatch" = "keyCode";
      };
    };
  };
}
