{ lib, ... }: {
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };
    useLayerShell = true;
    enableFirefoxIntegration = true;
  };

  programs.niri.settings = {
    binds."Mod+R" = lib.mkForce {
      hotkey-overlay.title = "Open vicinae launcher";
      action.spawn = [ "vicinae" "toggle" ];
    };
  };
}
