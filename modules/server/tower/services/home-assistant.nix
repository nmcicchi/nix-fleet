{ fleetSettings, pkgs, ... }: let
  user = "home-automation";
  cfg = fleetSettings.sequoia.users.${user};

  # container UID N (N >= 1) == subStart + N - 1.
  mosqHostId = toString (cfg.subStart + 1883 - 1); # eclipse-mosquitto runs as uid 1883
  hassUid = toString cfg.uid;                      # HA runs as container root
  z2mHostId = toString cfg.uid;                    # z2m runs as container root

  mqttPort = toString fleetSettings.sequoia.ports.mosquitto;
  z2mPort = toString fleetSettings.sequoia.ports.zigbee;

  mosquittoConf = pkgs.writeText "mosquitto.conf" ''
    listener 1883 0.0.0.0
    allow_anonymous true
  '';

  z2mConf = pkgs.writeText "configuration.yaml" ''
    version: 5
    mqtt:
      base_topic: zigbee2mqtt
      server: mqtt://127.0.0.1:${mqttPort}
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
      host: 127.0.0.1
      port: ${z2mPort}
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

  environment.persistence."/persist" = { directories = [ "var/lib/home-automation" ]; };

  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      homeassistant = {
        podman.user = user;
        image = "ghcr.io/home-assistant/home-assistant:stable";
        autoStart = true;
        extraOptions = [
          "--network=host"
          "--privileged"
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
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
          "127.0.0.1:${mqttPort}:1883"
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
        extraOptions = [
          "--network=host"
          # keep `dialout` so /dev/ttyACM0 is accessible (requires crun)
          "--group-add=keep-groups"
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

  systemd.tmpfiles.rules = [
    "d /var/lib/home-automation 0755 root root -"

    "d /var/lib/home-automation/home-assistant 0750 ${hassUid} ${hassUid} -"
    "Z /var/lib/home-automation/home-assistant - ${hassUid} ${hassUid} -"

    "d /var/lib/home-automation/mosquitto 0750 ${mosqHostId} ${mosqHostId} -"
    "d /var/lib/home-automation/mosquitto/data 0750 ${mosqHostId} ${mosqHostId} -"
    "d /var/lib/home-automation/mosquitto/log 0750 ${mosqHostId} ${mosqHostId} -"
    "Z /var/lib/home-automation/mosquitto - ${mosqHostId} ${mosqHostId} -"

    "d /var/lib/home-automation/zigbee2mqtt 0750 ${z2mHostId} ${z2mHostId} -"
    "Z /var/lib/home-automation/zigbee2mqtt - ${z2mHostId} ${z2mHostId} -"
    "C /var/lib/home-automation/zigbee2mqtt/configuration.yaml 0644 ${z2mHostId} ${z2mHostId} - ${z2mConf}"
  ];

  networking.firewall.allowedTCPPorts = [ fleetSettings.sequoia.ports.homeassistant ];
}
