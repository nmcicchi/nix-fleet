{ fleetSettings, ... }: let
  user = "hypermind";

in {
  imports = [
    (import ../../../../lib/mkPod.nix {
      name = user;
      inherit (fleetSettings.sequoia.users.hypermind) uid subStart subCount;
    })
  ];
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      hypermind = {
        podman.user = user;
        image = "ghcr.io/lklynet/hypermind:latest";
        extraOptions = [ "--network=host" ];
        environment = {
          PORT = toString fleetSettings.sequoia.ports.hypermind;
          ENABLE_CHAT = "true";
          ENABLE_MAP = "true";
        };
      };

      hypermind-swarm = {
        podman.user = user;
        image = "ghcr.io/lklynet/hypermind-swarm:latest";
        extraOptions = [ "--network=host" ];
        environment = {
          PORT = toString fleetSettings.sequoia.ports.hyperswarm;
        };
      };
    };
  };
}
