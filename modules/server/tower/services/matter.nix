{ fleetSettings, ... }: {
  # Enable the native Matter Python server
  services.matter-server = {
    enable = true;
    # Listen on port 5580 on all interfaces (or 127.0.0.1 if HA is on the same machine)
    listenAddress = "0.0.0.0";
    port = fleetSettings.sequoia.ports.matter;
  };
  networking = {
    # Enable IPv6 (Matter requires IPv6 link-local addressing for local mDNS discovery)
    enableIPv6 = true;
    firewall = {
      # Open the Matter Server WebSocket port if HA is on a different host/VLAN its not
      # allowedTCPPorts = [ fleetSettings.sequoia.ports.matter ];
      # Allow mDNS traffic for device discovery across subnets
      allowedUDPPorts = [ 5353 ];
    };
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/matter-server"
    ];
  };
}
