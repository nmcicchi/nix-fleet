{ config, lib, fleetSettings, ... }: let
  cfg = config.services.fleet-adguard;
  node = fleetSettings.${config.networking.hostName} or null;
in
{
  options.services.fleet-adguard = {
    enable = lib.mkEnableOption "Fleet-managed AdGuard Home instance";
  };

  config = lib.mkIf cfg.enable {
    # Ensure the current host is actually defined in your fleet settings
    assertions = [
      {
        assertion = node != null;
        message = "Host '${config.networking.hostName}' is missing from fleetSettings!";
      }
    ];

    services.adguardhome = {
      enable = true;
      mutableSettings = false;

      host = "127.0.0.1";
      port = node.ports.adguard.http;
      settings = {
        schema_version = 20;

        # Split-horizon DNS rules
        user_rules = [
          "||home^$client=192.168.0.0/16,dnsrewrite=${node.lan}"
          "||home^$client=100.64.0.0/10,dnsrewrite=${node.tail}"
        ];

        dns = {
          port = node.ports.adguard.dns;
          bind_hosts = [ 
            "0.0.0.0"
          ];

          private_networks = [ "100.64.0.0/10" "192.168.4.0/22" ];
          
          bootstrap_dns = [
            "1.1.1.1"
            "9.9.9.9"
          ];

          upstream_dns = [
            "https://dns.cloudflare.com/dns-query"
            "https://dns.quad9.net/dns-query"
          ];
        };

        filtering = {
          filtering_enabled = true;
          filters = [
            {
              enabled = true;
              id = 1;
              name = "AdGuard Base Filter";
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
            }
            {
              enabled = true;
              id = 2;
              name = "AdAway Mobile Ads";
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
            }
            {
              enabled = true;
              id = 1718223616;
              name = "OISD Blocklist Big";
              url = "https://big.oisd.nl";
            }
          ];
        };
      };
    };

    networking.firewall = {
      allowedUDPPorts = [ node.ports.adguard.dns ];
      allowedTCPPorts = [ node.ports.adguard.http ];
    };
  };
}
