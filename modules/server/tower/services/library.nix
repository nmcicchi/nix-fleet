{ fleetSettings, ... }: {
  # Enable Podman or Docker engine
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };

    oci-containers = {
      backend = "podman";

      containers = {
        # Ingestion Engine
        cwa = {
          image = "crocodilestick/calibre-web-automated:latest";
          autoStart = true;
          ports = [ "127.0.0.1:${toString fleetSettings.sequoia.ports.cwa}:8083" ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "UTC";
          };
          volumes = [
            "/media/ebooks/.cwa-config:/config"
            "/media/ebooks/ingest:/cwa-book-ingest"
            "/media/ebooks/library:/calibre-library"
          ];
        };

        # eBook Server & Reader
        kavita = {
          image = "lscr.io/linuxserver/kavita:latest";
          autoStart = true;
          ports = [ "127.0.0.1:${toString fleetSettings.sequoia.ports.kavita}:5000" ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "UTC";
          };
          volumes = [
            "/media/ebooks/.kavita-config:/config"
            "/media/ebooks/library:/data/books:ro" # Read-only access to managed library
          ];
        };
      };
    };
  };
  # Declaratively create and provision permissions
  systemd.tmpfiles.rules = [
    "d /media/ebooks 0775 1000 1000 -"
    "d /media/ebooks/ingest 0775 1000 1000 -"
    "d /media/ebooks/library 0775 1000 1000 -"
    # Im not sure i want the config files laid out like this,
    # they could either go in the same config directory or they could go in
    # appdata with the other service files like this
    "d /media/ebooks/.kavita-config 0775 1000 1000 -"
    "d /media/ebooks/.cwa-config 0775 1000 1000 -"
  ];
}
