{ config, fleetSettings, ... }:
let
  targetHost = "127.0.0.1";
in
{
  users = {
    groups.media = { };
    users = {
      nic.extraGroups = [ "media" "downloads" ];
      # lets lidarr read and move/delete torrents
      lidarr.extraGroups = [ "downloads" ];
    };
  };

  services = {
    navidrome = {
      enable = true;
      group = "media";
      settings = {
        Address = targetHost;
        Port = fleetSettings.sequoia.ports.navidrome;
        MusicFolder = "/media/music";
        ScanSchedule = "@every 15m";
        LogLevel = "info";
      };
    };

    lidarr = {
      enable = true;
      group = "media";
      settings = {
        update.mechanism = "external";
        server = {
          port = fleetSettings.sequoia.ports.lidarr;
          bindaddress = targetHost;
        };
        auth.required = "DisabledForLocalAddresses";
      };
      environmentFiles = [ config.sops.secrets.lidarr_env.path ];
    };

    # Register with the shared Prowlarr
    prowlarrLinks = {
      enable = true;
      apps.Lidarr = {
        port = fleetSettings.sequoia.ports.lidarr;
        envFile = config.sops.secrets.lidarr_env.path;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /media/music 0775 lidarr media -"
  ];
}
