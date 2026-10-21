{ fleetSettings, ... }:
{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;

    host = "127.0.0.1";
    port = fleetSettings.sequoia.ports.adguard.http;
    settings = {
      schema_version = 20;

      # Split-horizon DNS rules
      user_rules = [
        "||home^$client=192.168.0.0/16,dnsrewrite=${fleetSettings.sequoia.lan}"
        "||home^$client=100.64.0.0/10,dnsrewrite=${fleetSettings.sequoia.tail}"
      ];

      dns = {
        port = fleetSettings.sequoia.ports.adguard.dns;
        bind_hosts = [ 
          fleetSettings.sequoia.lan
          fleetSettings.sequoia.tail
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
    allowedUDPPorts = [ fleetSettings.sequoia.ports.adguard.dns ];
    allowedTCPPorts = [ fleetSettings.sequoia.ports.adguard.http ];
  };
}
