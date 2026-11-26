{
  self,
  config,
  fleetSettings,
  pkgs,
  ...
}:
let
  targetHost = "127.0.0.1";
  matrixPort = fleetSettings.sequoia.ports.matrix;
  appservicePort = fleetSettings.sequoia.ports.whatsapp;
in
{
  sops.secrets = {
    continuwuity_reg_token = {
      sopsFile = self + "/secrets/tower.yaml";
      owner = "continuwuity";
      mode = "0400";
    };
    mautrix_whatsapp_env = {
      sopsFile = self + "/secrets/tower.yaml";
      mode = "0400";
    };
  };

  services = {
    matrix-continuwuity = {
      enable = true;
      # using latest to avoid critical CVE
      package = pkgs.unstable.matrix-continuwuity;
      settings.global = {
        server_name = "matrix.home";
        address = [ targetHost ];
        port = [ matrixPort ];
        allow_registration = true; # Flip to false after creating @nic:matrix.home
        registration_token_file = config.sops.secrets.continuwuity_reg_token.path;
        allow_federation = false;
      };
    };

    mautrix-whatsapp = {
      enable = true;
      package = pkgs.unstable.mautrix-whatsapp;
      environmentFile = config.sops.secrets.mautrix_whatsapp_env.path;
      settings = {
        homeserver = {
          address = "http://${targetHost}:${toString matrixPort}";
          domain = "matrix.home";
        };
        appservice = {
          address = "http://${targetHost}:${toString appservicePort}";
          hostname = targetHost;
          port = appservicePort;
          id = "whatsapp";
          bot = {
            username = "whatsappbot";
            displayname = "WhatsApp Bridge Bot";
          };
        };
        database = {
          type = "sqlite3-fk-wal";
          uri = "file:/var/lib/mautrix-whatsapp/mautrix-whatsapp.db?_txlock=immediate";
        };
        bridge = {
          permissions = {
            "matrix.home" = "user";
            "@nic:matrix.home" = "admin";
          };
        };
        encryption = {
          allow = true;
          default = true;
          require = false;
          pickle_key = "$ENCRYPTION_PICKLE_KEY";
        };
      };
    };
  };

  # Add ffmpeg to whatsapp for media decoding
  systemd.services.mautrix-whatsapp.path = [ pkgs.ffmpeg ];

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/mautrix-whatsapp"
      "/var/lib/matrix-continuwuity"
    ];
  };
}
