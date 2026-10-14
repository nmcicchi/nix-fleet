{ fleetSettings, ... }: let 
  user = "library";
  cfg = fleetSettings.sequoia.users.library;

  puid = 1000;
  hostId = toString (cfg.subStart + puid - 1);
in {

  imports = [
    (import ../../../../lib/mkPod.nix {
      name = user;
      inherit (cfg) uid subStart subCount;
    })
  ];

  environment.persistence."/persist" = {
    directories = [
      { directory = "/var/lib/cwa"; inherit user; group = user; mode = "0750"; }
      { directory = "/var/lib/kavita"; inherit user; group = user; mode = "0750"; }
    ];
  };

  virtualisation = {
    oci-containers = {
      backend = "podman";

      containers = {
        cwa = {
          podman.user = user;
          image = "crocodilestick/calibre-web-automated:latest";
          autoStart = true;
          ports = [ "127.0.0.1:${toString fleetSettings.sequoia.ports.cwa}:8083" ];
          environment = {
            PUID = toString puid;
            PGID = toString puid;
            TZ = "UTC";
          };
          volumes = [
            "/var/lib/cwa:/config"
            "/media/ebooks/ingest:/cwa-book-ingest"
            "/media/ebooks/library:/calibre-library"
          ];
        };

        kavita = {
          podman.user = user;
          image = "lscr.io/linuxserver/kavita:latest";
          autoStart = true;
          ports = [ "127.0.0.1:${toString fleetSettings.sequoia.ports.kavita}:5000" ];
          environment = {
            PUID = toString puid;
            PGID = toString puid;
            TZ = "UTC";
          };
          volumes = [
            "/var/lib/kavita:/config"
            "/media/ebooks/library:/data/books:ro" # Read-only access to managed library
          ];
        };
      };
    };
  };

  # 3. Declaratively provision permissions using the shifted rootless host ID
  systemd.tmpfiles.rules = [
    "d /var/lib/cwa 0750 ${hostId} ${hostId} -"
    "Z /var/lib/cwa - ${hostId} ${hostId} -"
    "d /var/lib/kavita 0750 ${hostId} ${hostId} -"
    "Z /var/lib/kavita - ${hostId} ${hostId} -"

    "d /media/ebooks 0775 ${hostId} ${hostId} -"
    "d /media/ebooks/ingest 0775 ${hostId} ${hostId} -"
    "d /media/ebooks/library 0775 ${hostId} ${hostId} -"
  ];
}
