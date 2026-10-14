{ fleetSettings, ... }: let
  user = "matter";
in {
  imports = [
    (import ../../../../lib/mkPod.nix{
      name = user;
      inherit (fleetSettings.sequoia.users.matter) uid subStart subCount;
    })
  ];

  virtualisation = {
    oci-containers = {
      backend = "podman";

      containers.matter-server = {
        podman.user = user;
        image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
        autoStart = true;
        
        extraOptions = [
          "--network=host"
        ];

        volumes = [
          "/var/lib/matter-server:/data"
        ];

        environment = {
          PORT = toString fleetSettings.sequoia.ports.matter;
        };
      };
    };
  };

  environment.persistence."/persist" = {
    directories = [
      { directory = "/var/lib/matter-server"; inherit user; group = user; mode = "0700"; }
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/matter-server 0700 ${user} ${user} -"
    "Z /var/lib/matter-server - ${user} ${user} -"
  ];

  # Host network configuration
  networking = {
    enableIPv6 = true;
    firewall = {
      allowedTCPPorts = [ fleetSettings.sequoia.ports.matter ];
      allowedUDPPorts = [ 5353 ]; # mDNS
    };
  };
}
