{ fleetSettings, ... }:
let
  # Helper function to map a service string to an Nginx virtualHost attribute pair
  mkLocalProxy = host: service: {
    name = "${service}.home";
    value = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString fleetSettings.${host}.ports.${service}}";
      };
    };
  };

  # Generate the repetitive localhost virtual hosts for Sequoia
  sequoiaStandardHosts = builtins.listToAttrs (map (mkLocalProxy "sequoia") [
    "hypermind"
    "hyperswarm"
    "navidrome"
    "prowlarr"
    "grafana"
    "glances"
    "lidarr"
    "zigbee"
    "kavita"
    "cwa"
  ]);

  # Non-standard or unique mappings that break the cookie-cutter pattern
  customHosts = {
    "searxng.home" = {
      locations."/" = {
        proxyPass = "http://${fleetSettings.sequoia.containers.searxng}";
        proxyWebsockets = true;
      };
    };

    "librechat.home" = {
      locations."/" = {
        proxyPass = "http://${toString fleetSettings.aspen.lan}:${toString fleetSettings.aspen.ports.librechat}";
        proxyWebsockets = true;
      };
    };

    "homeassistant.home" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString fleetSettings.sequoia.ports.homeassistant}";
        proxyWebsockets = true;
      };
    };

    "adguard.home" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString fleetSettings.sequoia.ports.adguard.http}";
      };
    };

    "sabnzbd.home" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString fleetSettings.sequoia.ports.sabnzbd}";
        
        # Explicitly pass the original host header down to SABnzbd
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };
in
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Merge the dynamically generated set with the custom overrides
    virtualHosts = sequoiaStandardHosts // customHosts;
  };

  networking.firewall.allowedTCPPorts = [ fleetSettings.sequoia.ports.nginx ];
}
