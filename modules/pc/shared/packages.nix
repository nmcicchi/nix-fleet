{ pkgs, nvfFN, ... }: let
  stable = with pkgs; [
    rclone
    ripgrep
    numix-cursor-theme # cursor
    tealdeer # tldr tool
    zathura # terminal pdf viewer
    prismlauncher # minecraft
    unzip
    zip
    pavucontrol # audio
    brightnessctl # brightness
    vesktop # discord
    tailspin # log highlighter
    wiremix # audio output tui
    home-manager # dont delete this

    noctalia-shell
  ];
  
  nvfPkg = nvfFN pkgs.unstable;
in {
  environment.systemPackages = stable ++ [ nvfPkg ];

  services.flatpak = {
    enable = true;

    packages = [
      "com.rtosta.zapzap"
      "org.vinegarhq.Sober"
      "com.github.tchx84.Flatseal"
    ];

    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}
