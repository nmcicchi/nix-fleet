# not finished yet
_: let
  username = "Nic";
in {
  services.syncthing = {
    enable = true;
    user = "${username}";
    dataDir = "/home/${username}";
    configDir = "/home/${username}/.config/syncthing";
    openDefaultPorts = true;
    
    # Allows managing/adding unmanaged folders via GUI if needed
    overrideFolders = true;
    overrideDevices = true;

    settings = {
      devices = {
        "server" = { id = "DEVICE-ID-HERE"; };
      };

      gui.enabled = false;

      folders = {
        "School" = {
          path = "/home/${username}/school";
          devices = [ "server" ];
          watch = true;
        };
      };
    };
  };
}
