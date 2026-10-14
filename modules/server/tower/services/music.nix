# Needs to be configured with qbit and have user permissions set up
{ config, pkgs, fleetSettings, ... }:
let
  targetHost = "127.0.0.1";
in
{
  # Unified Shared Media Permissions Architecture
  users.groups.media = { };
  users.users.nic.extraGroups = [ "media" ];

  services = {
    # Navidrome - The Front-End Media Streamer
    navidrome = {
      enable = true;
      group = "media"; # Align permissions so Navidrome can parse Lidarr imports
      settings = {
        Address = targetHost;
        Port = fleetSettings.sequoia.ports.navidrome;
        MusicFolder = "/media/music";
        ScanSchedule = "@every 15m";
        LogLevel = "info";
      };
    };
    # Lidarr - The Music Collection & Automation Manager
    lidarr = {
      enable = true;
      group = "media";
      settings = {
        update = { mechanism = "external"; }; # Strictly immutable/declarative tracking via flakes
        server = {
          port = fleetSettings.sequoia.ports.lidarr;
          bindaddress = targetHost;
        };
        auth.required = "DisabledForLocalAddresses";
      };
      environmentFiles = [ config.sops.secrets.lidarr_env.path ];
    };

    # Prowlarr - The Indexer Synchronization Layer
    prowlarr = {
      enable = true;
      settings = {
        update = { mechanism = "external"; };
        server = {
          port = fleetSettings.sequoia.ports.prowlarr;
          bindaddress = targetHost;
        };
        auth.required = "DisabledForLocalAddresses";
      };
      environmentFiles = [ config.sops.secrets.prowlarr_env.path ];
    };
  };

  systemd = {
    # Automated Persistent Storage Scaffolding & Permissions Enforcement
    tmpfiles.rules = [
      "d /media/music 0775 lidarr media -"
    ];
    services = {
        prowlarr-link-lidarr = {
        description = "Link Lidarr to Prowlarr API indexer sync";
        after = [ "prowlarr.service" "lidarr.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = let
            linkApp = pkgs.replaceVarsWith {
              src = ../../../../lib/connect-to-prowlarr.sh;
              dir = "bin";
              isExecutable = true;
              replacements = {
                scriptPath = pkgs.lib.makeBinPath [ pkgs.curl pkgs.gnused pkgs.gnugrep ];
                prowlarrPort = toString fleetSettings.sequoia.ports.prowlarr;
                subAppPort = toString fleetSettings.sequoia.ports.lidarr;
                subAppName = "Lidarr";
                prowlarrEnvPath = config.sops.secrets.prowlarr_env.path;
                subAppEnvPath = config.sops.secrets.lidarr_env.path;
              };
            };
          in "${linkApp}/bin/connect-to-prowlarr.sh";
        };
      };
    };
  };
}
