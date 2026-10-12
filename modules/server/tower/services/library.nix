{ fleetSettings, ... }: {
  # Enable Podman or Docker engine
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      # defaultNetwork.settings.dns_enabled = true;
    };

    oci-containers = {
      backend = "podman";

      containers = {
        # Ingestion Engine
        cwa = {
          image = "crocodilestick/calibre-web-automated:latest";
          autoStart = true;
          ports = [ "${fleetSettings.sequoia.ports.cwa}:8083" ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "UTC";
          };
          volumes = [
            "/media/ebooks/cwa-config:/config"
            "/media/ebooks/ingest:/cwa-book-ingest"
            "/media/ebooks/library:/calibre-library"
          ];
        };

        # eBook Server & Reader
        kavita = {
          image = "lscr.io/linuxserver/kavita:latest";
          autoStart = true;
          ports = [ "${fleetSettings.sequoia.ports.kavita}:5000" ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "UTC";
          };
          volumes = [
            "/media/ebooks/kavita-config:/config"
            "/media/ebooks/library:/data/books:ro" # Read-only access to managed library
          ];
        };
      };
    };
  };
}
