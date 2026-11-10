{ fleetSettings, ... }:
let
  user = "flaresolverr";
in {
  imports = [
    (import ../../../../lib/mkPod.nix {
      name = user;
      inherit (fleetSettings.sequoia.users.flaresolverr) uid subStart subCount;
    })
  ];

  virtualisation = {
    oci-containers = {
      backend = "podman";

      containers.flaresolverr = {
        podman.user = user;
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        autoStart = true;
        
        ports = [
          "127.0.0.1:${toString fleetSettings.sequoia.ports.flaresolverr}:8191"
        ];

        environment = {
          TZ = "America/New_York";
          LOG_LEVEL = "info";
        };
      };
    };
  };
}
