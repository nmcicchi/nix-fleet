{ fleetSettings, ... }: {
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.matter-server = {
    image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
    autoStart = true;
    
    # Host networking gives the container direct access to IPv6 & mDNS traffic
    extraOptions = [
      "--network=host"
    ];

    volumes = [
      # Store state directly on /persist to bypass tmpfs root impermanence
      "/persist/var/lib/matter-server:/data"
    ];

    environment = {
      PORT = toString fleetSettings.sequoia.ports.matter;
    };
  };

  # Host network configuration
  networking = {
    enableIPv6 = true;
    firewall = {
      allowedTCPPorts = [ fleetSettings.sequoia.ports.matter ];
      allowedUDPPorts = [ 5353 ]; # mDNS
    };
  };
}
