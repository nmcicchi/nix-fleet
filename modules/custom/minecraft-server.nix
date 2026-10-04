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

      # Option A: Declarative individual mods fetched via Nix
      mods = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "List of pkgs.fetchurl mod packages to mount read-only into /data/mods.";
      };

      # Option B: Dynamic Modpack URL or Modrinth Slug/Link
      modpackUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Direct URL to a .zip or .mrpack modpack file.";
      };
      modrinthModpack = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Modrinth modpack slug, version ID, or URL.";
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
        difficulty = mkOption {
          type = types.enum [ "peaceful" "easy" "normal" "hard" ];
          default = "normal";
        };
        autopause = mkOption {
          type = types.int;
          default = 300;
        };
        mode = mkOption {
          type = types.enum [ "survival" "creative" "adventure" "spectator" ];
          default = "survival";
        };
      };
    };
  };

  mkContainers = name: instance:
    let
      hasNixMods = instance.mods != [ ];

      modpackStore = pkgs.runCommand "${name}-mods" { } ''
        mkdir -p $out
        ${concatMapStringsSep "\n" (mod: "ln -s ${mod} $out/${mod.name}") instance.mods}
      '';

      # Only mount the read-only Nix store path if declarative mods exist.
      # Otherwise, leave /data/mods inside appdata writable for dynamic downloads.
      volumes = [ "/appdata/${name}/data:/data" ]
        ++ optional hasNixMods "${modpackStore}:/data/mods";

      # Dynamic modpack environment variables
      modpackEnv = 
        optionalAttrs (instance.modpackUrl != null) { MODPACK = instance.modpackUrl; }
        // optionalAttrs (instance.modrinthModpack != null) { MODRINTH_MODPACK = instance.modrinthModpack; };
    in {
      "${name}" = {
        inherit (instance) image;
        inherit volumes;
        dependsOn = [ instance.tsContainerName ];
        extraOptions = [
          "--network=lan-bridge"
          "--ip=${instance.mcIp}"
        ];
        environment = {
          EULA = "TRUE";
          TYPE = "FABRIC";
          TZ = "America/New_York";
          VERSION = instance.environment.version;
          MEMORY = instance.environment.memory;
          JVM_OPTS = aikarFlags;
          ENABLE_AUTOPAUSE = "TRUE";
          MAX_TICK_TIME = "-1";
          AUTOPAUSE_TIMEOUT_EST = toString instance.environment.autopause;
          VIEW_DISTANCE = toString instance.environment.viewDistance;
          SIMULATION_DISTANCE = toString instance.environment.simulationDistance;
          OPS = instance.environment.admin;
          WHITELIST = instance.environment.whitelist;
          ENFORCE_WHITELIST = instance.environment.enforceWhitelist;
          DIFFICULTY = instance.environment.difficulty;
          MODE = instance.environment.mode;
        } // modpackEnv;
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
          TS_STATEFUL_CONFIG = "true";
          TS_AUTH_ONCE = "true";
          TS_HOSTNAME = instance.tsContainerName;
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
