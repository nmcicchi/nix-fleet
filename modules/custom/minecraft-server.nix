{ config, lib, pkgs, fleetSettings, ... }:

with lib;

let
  cfg = config.services.minecraft-instances;
  activeInstances = filterAttrs (_name: instance: instance.enable) cfg;

  aikarFlags = "-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8m -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1";

  admin = "MrChuwu";

  # Every container unit needs the macvlan network to exist first.
  bridgeUnit = "podman-lan-bridge.service";

  instanceOptions = { name, ... }: {
    options = {
      enable = mkEnableOption "this Minecraft instance";

      image = mkOption {
        type = types.str;
        default = "itzg/minecraft-server:latest";
      };
      tsContainerName = mkOption {
        type = types.str;
        default = "${name}-ts";
      };
      tsStateDir = mkOption {
        type = types.str;
        default = "/var/lib/tailscale-${name}";
      };
      mods = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
      mcIp = mkOption {
        type = types.str;
      };
      tsIp = mkOption {
        type = types.str;
      };
      environment = {
        memory = mkOption {
          type = types.str;
          default = "12G";
        };
        viewDistance = mkOption {
          type = types.int;
          default = 16;
        };
        simulationDistance = mkOption {
          type = types.int;
          default = 8;
        };
        admin = mkOption {
          type = types.str;
          default = admin;
        };
        version = mkOption {
          type = types.str;
        };
        whitelist = mkOption {
          type = types.str;
          default = admin;
        };
        enforceWhitelist = mkOption {
          type = types.str;
          default = "TRUE";
        };
      };
    };
  };

  mkContainers = name: instance:
    let
      modpack = pkgs.runCommand "${name}-mods" { } ''
        mkdir -p $out
        ${concatMapStringsSep "\n" (mod: "ln -s ${mod} $out/${mod.name}") instance.mods}
      '';
    in {
      "${name}" = {
        inherit (instance) image;
        dependsOn = [ instance.tsContainerName ];
        extraOptions = [
          "--network=lan-bridge"
          "--ip=${instance.mcIp}"
        ];
        volumes = [
          "/appdata/${name}/data:/data"
          "${modpack}:/data/mods"
        ];
        environment = {
          EULA = "TRUE";
          TYPE = "FABRIC";
          VERSION = instance.environment.version;
          MEMORY = instance.environment.memory;
          JVM_OPTS = aikarFlags;
          ENABLE_AUTOPAUSE = "TRUE";
          MAX_TICK_TIME = "-1";
          AUTOPAUSE_TIMEOUT_EST = "300";
          VIEW_DISTANCE = toString instance.environment.viewDistance;
          SIMULATION_DISTANCE = toString instance.environment.simulationDistance;
          OPS = instance.environment.admin;
          WHITELIST = instance.environment.whitelist;
          ENFORCE_WHITELIST = instance.environment.enforceWhitelist;
        };
      };

      "${instance.tsContainerName}" = {
        image = "tailscale/tailscale:latest";
        extraOptions = [
          "--network=lan-bridge"
          "--ip=${instance.tsIp}"
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
          "--device=/dev/net/tun"
          "--sysctl=net.ipv4.ip_forward=1"
        ];
        volumes = [
          "${instance.tsStateDir}:/var/lib/tailscale"
          "${config.sops.secrets.tailscale_key.path}:/run/secrets/tailscale_key:ro"
        ];
        environment = {
          TS_AUTHKEY = "file:///run/secrets/tailscale_key";
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_AUTH_ONCE = "true";
          TS_USERSPACE = "false";
          TS_HOSTNAME = name;
          TS_ROUTES = "${instance.mcIp}/32";
          TS_EXTRA_ARGS = "--snat-subnet-routes=true";
        };
      };
    };

  mkServiceOverrides = name: instance: {
    "podman-${instance.tsContainerName}" = {
      requires = [ bridgeUnit ];
      after = [ bridgeUnit ];
      preStart = mkBefore ''
        mkdir -p ${escapeShellArg instance.tsStateDir}
        chmod 700 ${escapeShellArg instance.tsStateDir}
      '';
    };

    "podman-${name}" = {
      requires = [ bridgeUnit ];
      after = [ bridgeUnit ];
      preStart = mkBefore ''
        mkdir -p /appdata/${escapeShellArg name}/data
      '';
    };
  };

in {
  options.services.minecraft-instances = mkOption {
    type = types.attrsOf (types.submodule instanceOptions);
    default = { };
  };

  config = mkIf (cfg != { }) {

    systemd.services = {
      podman-lan-bridge = {
        description = "Create podman macvlan network lan-bridge";
        path = [ pkgs.podman ];
        script = ''
          podman network exists lan-bridge || \
          podman network create -d macvlan -o parent=br0 \
            --subnet ${fleetSettings.network.subnet}/${toString fleetSettings.network.subnetPrefix} \
            --gateway ${fleetSettings.network.gateway} lan-bridge
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        wantedBy = [ "multi-user.target" ];
        bindsTo = [ "sys-subsystem-net-devices-br0.device" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" "sys-subsystem-net-devices-br0.device" ];
      };
    } // concatMapAttrs mkServiceOverrides activeInstances;

    virtualisation = {
      podman = {
        enable = true;
        dockerSocket.enable = true;
      };

      oci-containers = {
        backend = "podman";
        containers = concatMapAttrs mkContainers activeInstances;
      };
    };
  };
}
