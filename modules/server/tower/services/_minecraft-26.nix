{ config, pkgs, fleetSettings, ... }: 
let
  mods26-1 = [
    (pkgs.fetchurl {
      name = "ferritecore-9.0";
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/d5ddUdiB/ferritecore-9.0.0-fabric.jar?mr_download_reason=standalone";
      sha256 = "sha256-ITlmxy7ZZ6zHOSvrKKhm+6MB/1a5l2wueAHC233mvyI=";
    })
    (pkgs.fetchurl {
      name = "chunky-1.5.3";
      url = "https://cdn.modrinth.com/data/fALzjamp/versions/4Eotm6ov/Chunky-Fabric-1.5.3.jar";
      sha256 = "sha256-7N/FWg9n8+xvQIUGh2FclBriJr2I9OBhiKeyaP09qUI=";
    })
    (pkgs.fetchurl {
      name = "servercore-1.5.17";
      url = "https://cdn.modrinth.com/data/4WWQxlQP/versions/2siue87F/servercore-fabric-1.5.17%2B26.1.2.jar";
      sha256 = "sha256-TIMlZiFdj/3NsWv3utkIoduZZo2YpDaWQ2apxNhL3cA=";
    })
  ];

  makeModpack = name: modlist: pkgs.runCommand name {} ''
    mkdir -p $out
    ${pkgs.lib.concatMapStringsSep "\n" (mod: "ln -s ${mod} $out/${mod.name}") modlist}
  '';

  modpack26-1 = makeModpack "mc-mods-26-1" mods26-1;

  aikarFlags = "-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8m -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1";
in
{
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
  };

  virtualisation.arion = {
    backend = "podman-socket";
    projects.minecraft-26.settings = {
      project.name = "minecraft-26";

      # Attach directly to the existing br0 host bridge
      networks.lan-bridge = {
        name = "lan-bridge";
        driver = "macvlan";
        driver_opts.parent = "br0";
        ipam.config = [{
          subnet = fleetSettings.network.subnet + "/${toString fleetSettings.network.subnetPrefix}";
          gateway = fleetSettings.network.gateway;
        }];
      };

      services.mc-ts = {
        service = {
          image = "tailscale/tailscale:latest";
          
          # Assign a dedicated, distinct IP for the Tailscale sidecar container
          networks.lan-bridge = {
            ipv4_address = fleetSettings.sequoia.containers.mc-26.router;
          };

          volumes = [
            "/var/lib/tailscale-mc-26:/var/lib/tailscale"
            "/dev/net/tun:/dev/net/tun"
            "${config.sops.secrets.tailscale_key.path}:/run/secrets/tailscale_key:ro"
          ];

          environment = {
            TS_AUTHKEY = "file:///run/secrets/tailscale_key";
            TS_STATEFUL_CONFIG = "true";
            TS_HOSTNAME = "mc-26";
            # Subnet route advertising the Minecraft container's dedicated LAN IP into Tailscale
            TS_ROUTES = "${fleetSettings.sequoia.containers.mc-26.lan}/32";
            TS_EXTRA_ARGS = "--snat-subnet-routes=true";
          };
          capabilities = { NET_ADMIN = true; NET_RAW = true; };

          sysctls = {
            "net.ipv4.ip_forward" = "1";
          };

          restart = "unless-stopped";
        };
      };

      services.minecraft-latest = {
        service = {
          image = "itzg/minecraft-server:latest";
          
          # Container gets its dedicated LAN IP on br0 (192.168.5.103)
          networks.lan-bridge = {
            ipv4_address = fleetSettings.sequoia.containers.mc-26.lan;
          };

          volumes = [
            "/appdata/minecraft-latest/data:/data"
            "${modpack26-1}:/data/mods"
          ];

          environment = {
            EULA = "TRUE";
            TYPE = "FABRIC";
            VERSION = "26.1.2";
            MEMORY = "12G";
            JVM_OPTS = aikarFlags;
            ENABLE_AUTOPAUSE = "TRUE";
            MAX_TICK_TIME = "-1"; 
            AUTPAUS_TIMEOUT_EST = "300";
            VIEW_DISTANCE = "16";
            SIMULATION_DISTANCE = "8";
            OPS = "MrChuwu";
            WHITELIST = "MrChuwu";
            ENFORCE_WHITELIST = "TRUE";
          };
          restart = "unless-stopped";
        };
      };
    };
  };

  systemd.services.arion-minecraft-26 = {
    after = [ "podman.socket" "podman.service" "network-online.target" ];
    wants = [ "podman.socket" "network-online.target" ];
    requires = [ "podman.socket" ];
    environment = {
      DOCKER_HOST = "unix:///run/podman/podman.sock";
    };
  };
}
