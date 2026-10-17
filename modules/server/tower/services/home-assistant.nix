{ fleetSettings, pkgs, ... }: let
  user = "home-automation";
  cfg = fleetSettings.sequoia.users.${user};

  # Shifted host IDs for internal container users
  mosqHostId = toString (cfg.subStart + 1883 - 1);
  hassUid = cfg.uid;
  z2mHostId = toString cfg.uid;

  mosquittoConf = pkgs.writeText "mosquitto.conf" ''
    listener 1883 0.0.0.0
    allow_anonymous true
  '';

  z2mConf = pkgs.writeText "configuration.yaml" ''
    version: 5
    mqtt:
      base_topic: zigbee2mqtt
      server: mqtt://127.0.0.1:1883
    serial:
      port: /dev/ttyACM0
      adapter: zstack
    advanced:
      log_level: info
      channel: 11
      network_key: GENERATE
      pan_id: GENERATE
      ext_pan_id: GENERATE
      enable_external_js: false
    frontend:
      enabled: true
      port: 8080
    homeassistant:
      enabled: true
    onboarding: false
  '';
in {
  imports = [
    (import ../../../../lib/mkPod.nix {
      name = user;
      inherit (cfg) uid subStart subCount;
    })
  ];

  # Give the rootless user access to host serial devices
  users.users.${user}.extraGroups = [ "dialout" ];

  environment.persistence."/persist" = {
    directories = [
      { directory = "/var/lib/home-automation"; inherit user; group = user; mode = "0750"; }
    ];
  };

  virtualisation = {
    oci-containers = {
      backend = "podman";

      containers = {
        homeassistant = {
          podman.user = user;
          image = "ghcr.io/home-assistant/home-assistant:stable";
          autoStart = true;
          extraOptions = [
            "--network=host"
            "--privileged"
          ];
          volumes = [
            "/var/lib/home-automation/home-assistant:/config"
            "/etc/localtime:/etc/localtime:ro"
            "/run/dbus:/run/dbus:ro"
          ];
          environment = {
            TZ = toString fleetSettings.network.tz;
          };
        };

        mosquitto = {
          podman.user = user;
          image = "eclipse-mosquitto:2";
          autoStart = true;
          ports = [
            "127.0.0.1:${toString fleetSettings.sequoia.ports.mosquitto}:1883"
          ];
          volumes = [
            "/var/lib/home-automation/mosquitto/data:/mosquitto/data"
            "/var/lib/home-automation/mosquitto/log:/mosquitto/log"
            "${mosquittoConf}:/mosquitto/config/mosquitto.conf:ro"
          ];
        };

        zigbee2mqtt = {
          podman.user = user;
          image = "ghcr.io/koenkk/zigbee2mqtt:latest";
          autoStart = true;
          ports = [
            "127.0.0.1:${toString fleetSettings.sequoia.ports.zigbee}:8080"
          ];
          volumes = [
            "/var/lib/home-automation/zigbee2mqtt:/app/data"
            "/run/udev:/run/udev:ro"
          ];
          devices = [
            "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_CC2674P10_90352febbffef01197d3f41f364a576b-if00-port0:/dev/ttyACM0"
          ];
          environment = {
            TZ = toString fleetSettings.network.tz;
          };
          dependsOn = [
            "mosquitto"
          ];
        };
      };
    };
  };

  # Declaratively provision permissions with correct shifted host UIDs
  systemd.tmpfiles.rules = [
    "d /var/lib/home-automation 0750 ${toString hassUid} ${toString hassUid} -"
    "Z /var/lib/home-automation/home-assistant 0750 ${toString hassUid} ${toString hassUid} -"
    
    "d /var/lib/home-automation/mosquitto 0750 ${mosqHostId} ${mosqHostId} -"
    "Z /var/lib/home-automation/mosquitto/data - ${mosqHostId} ${mosqHostId} -"
    
    "d /var/lib/home-automation/zigbee2mqtt 0750 ${z2mHostId} ${z2mHostId} -"
    "Z /var/lib/home-automation/zigbee2mqtt - ${z2mHostId} ${z2mHostId} -"
    "C /var/lib/home-automation/zigbee2mqtt/configuration.yaml 0644 ${z2mHostId} ${z2mHostId} - ${z2mConf}"
  ];

  networking.firewall.allowedTCPPorts = [ fleetSettings.sequoia.ports.homeassistant ];
}
