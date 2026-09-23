{ pkgs, ... }: {
  programs = {
    zsh.interactiveShellInit = ''
    '';
    nh = {
      enable = true;
      clean.enable = true;

      flake = "/home/nic/nix-fleet/";
    };
    # Enables direnv
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
      # make direnv quiet
      settings.global.hide_env_diff = true;
    };
  };

  environment.systemPackages = [ pkgs.devenv ];
}
