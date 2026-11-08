{ lib, ... }: {
  programs = {
    vicinae = {
      enable = true;
    };
    niri.settings.binds. "Mod+R" = lib.mkForce {
      hot-key-overlay.title = "Open vicinae launcher";
      action.spawn = [ "vicinae open" ];
    };
  };
}
