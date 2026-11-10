# Shared Prowlarr instance + a tiny registry for the *arr apps that should
# receive its indexers. Import this once on the host; every media module
# (music, tv, movies, ...) then just declares itself:
#
#   services.prowlarrLinks.apps.Sonarr = {
#     port = fleetSettings.sequoia.ports.sonarr;
#     envFile = config.sops.secrets.sonarr_env.path;
#   };
#
# The attribute name MUST be the Prowlarr implementation name
# ("Lidarr", "Sonarr", "Radarr", "Readarr", ...). The matching systemd unit
# is assumed to be the lowercase name (lidarr.service, ...), and the app's
# env file is assumed to export <UPPERNAME>__AUTH__APIKEY.
{ config, pkgs, lib, fleetSettings, ... }:
let
  cfg = config.services.prowlarrLinks;
  targetHost = "127.0.0.1";
in
{
  options.services.prowlarrLinks.apps = lib.mkOption {
    default = { };
    description = "Apps Prowlarr should push indexers to, keyed by Prowlarr implementation name.";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = "Port the app listens on (on 127.0.0.1).";
        };
        envFile = lib.mkOption {
          type = lib.types.either lib.types.path lib.types.str;
          description = "Env file containing <NAME>__AUTH__APIKEY.";
        };
      };
    });
  };

  config = {
    services.prowlarr = {
      enable = true;
      settings = {
        update.mechanism = "external";
        server = {
          port = fleetSettings.sequoia.ports.prowlarr;
          bindaddress = targetHost;
        };
        auth.required = "DisabledForLocalAddresses";
      };
      environmentFiles = [ config.sops.secrets.prowlarr_env.path ];
    };

    # One oneshot per registered app
    systemd.services = lib.mapAttrs'
      (name: app:
        let unit = "${lib.toLower name}.service"; in
        lib.nameValuePair "prowlarr-link-${lib.toLower name}" {
          description = "Link ${name} to Prowlarr API indexer sync";
          wantedBy = [ "multi-user.target" ];
          requires = [ "prowlarr.service" unit ];
          after = [ "prowlarr.service" unit ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart =
              let
                linkApp = pkgs.replaceVarsWith {
                  src = ./../../lib/connect-to-prowlarr.sh;
                  dir = "bin";
                  isExecutable = true;
                  replacements = {
                    scriptPath = lib.makeBinPath [ pkgs.curl pkgs.gnused pkgs.gnugrep ];
                    prowlarrPort = toString fleetSettings.sequoia.ports.prowlarr;
                    subAppPort = toString app.port;
                    subAppName = name;
                    prowlarrEnvPath = config.sops.secrets.prowlarr_env.path;
                    subAppEnvPath = toString app.envFile;
                  };
                };
              in "${linkApp}/bin/connect-to-prowlarr.sh";
          };
        })
      cfg.apps;
  };
}
