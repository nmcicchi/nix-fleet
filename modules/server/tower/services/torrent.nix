{ config, fleetSettings, ... }: {
  sops.secrets.tailscale_torrent_key = {
    sopsFile = ../../../../secrets/tower.yaml;
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/tailscale-torrent"
    ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    #defaultNetwork.settings.dns_enabled = true;
  };

  # Podman OCI containers stack
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      tailscale-torrent = {
        image = "docker.io/tailscale/tailscale:latest";
        environment = {
          TS_AUTHKEY_FILE = config.sops.secrets.tailscale_torrent_key.path;
          TS_STATE_DIR = "/var/lib/tailscale-torrent";
          TS_EXTRA_ARGS = "--exit-node=${fleetSettings.sequia.containers.tail-torrent} --exit-node-allow-lan-access=false";
        };
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
        volumes = [
          "/var/lib/tailscale-torrent:/var/lib/tailscale-torrent"
        ];
      };

      qbittorrent = {
        image = "docker.io/lscr.io/linuxserver/qbittorrent:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "UTC";
          WEBUI_PORT = "${toString fleetSettings.sequia.ports.qbit}";
        };
        volumes = [
          "/appdata/qbittorrent:/config"
          "/media/downloads:/downloads"
        ];
        extraOptions = [
          "--network=container:tailscale-torrent"
        ];
      };
    };
  };
}
