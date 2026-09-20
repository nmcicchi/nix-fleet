{ fleetSetting, ... }: let
  username = "Nic";
in
{
  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "/home/${username}";
    configDir = "/home/${username}/.config/syncthing";

    overrideFolders = true;
    overrideDevices = true;

    settings = {
      devices = {
        "laptop" = { id = "SERVER-DEVICE-ID-HERE"; };
        "desktop" = { id = "SERVER-DEVICE-ID-HERE"; };
      };

      folders = {
        "School" = {
          path = "/home/${username}/school";
          devices = [ "laptop" "desktop" ];
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "1555200"; # 180 days
            };
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ fleetSetting.sequoia.ports.syncthing ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}
