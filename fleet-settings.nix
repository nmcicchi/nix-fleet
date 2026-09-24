# This file creates network variables
# note that tailscale address are not static and may be outdated
{
  sequoia = {
    lan = "192.168.5.100";
    tail = "100.104.58.30"; # this is critical for adguard to work
    shim = "192.168.6.200";

    containers = {
      searxng = "192.168.5.101";
      mc-20 = {
        lan = "192.168.5.102";
        router = "192.168.5.106";
        tail = "";
      };
      mc-26 = {
        lan = "192.168.5.103";
        router = "192.168.5.104";
        tail = "";
      };
    };

    ports = {
      # Media Server
      navidrome = 4533;
      sabnzbd = 8085;
      lidarr = 8686;
      prowlarr = 9696;
      homeassistant = 8123; # forced cause docker
      mosquitto = 1883;
      zigbee = 8125;
      syncthing = 22000; #hardcoded atm

      # Infrastructure
      prometheus = {
        exporter = 9100;
        service = 9090;
      };
      grafana = 3000;
      glances = 61208;
      nginx = 80;
      adguard = {
        http = 3080;
        dns = 53;
      };
# Others
      hypermind = 3001;
      hyperswarm = 3002;
    };

  };

  juniper = {
    lan = "192.168.5.99";
    wifi = "192.168.5.98";
    tail = "100.108.233.1";

    ports = {
      prometheus = 9100;
      adguard = {
        http = 3080;
        dns = 53;
      };
    };
  };

  rowan = {
    lan = "192.168.5.89";
    wifi = "192.168.5.88";
    
    ports = {
      glances = 61208;
      prometheus = 9100;
    };
  };

  aspen = {
    lan = "192.168.5.79";
    wifi = "192.168.5.78";
    ports = {
      ollama = 11434;
      librechat = 3080;
      mongodb = 27017; # this is hardcoded in laptop.yaml
      whisper = 10300;
      piper = 10200;
      wakeWord = 10400;
      glances = 61208;
      prometheus = 9100;
    };
  };

  network = {
    subnet = "192.168.4.0";
    subnetPrefix = 22;
    gateway = "192.168.4.1";
    dns = [ "192.168.4.1" "1.1.1.1" ];
    ssid = "MikroTik-75856A";
    tz = "America/New_York";
  };
}
