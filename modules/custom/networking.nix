{ config, lib, fleetSettings ? null, networkSettings ? null, ... }:

let
  cfg = config.mySystem.networking;

  # Handle static IP calculations safely if settings are passed via specialArgs
  subnetPrefix = if networkSettings != null then toString networkSettings.subnetPrefix else "";
  hasWifi = (fleetSettings != null) && (fleetSettings ? wifi) && (fleetSettings.wifi != null);

  wifiSsid = networkSettings.ssid or "MikroTik-75856A";

in
{
  # OPTION DECLARATIONS
  options.mySystem.networking = {
    enable = lib.mkEnableOption "shared base networking stack";

    enableStaticInterfaces = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable systemd-networkd static Ethernet/Wi-Fi interface provisioning.";
    };
  };

  # MODULE CONFIGURATION
  config = lib.mkMerge [
    
    # Base Networking
    (lib.mkIf cfg.enable {
      services = {
        openssh = {
          enable = true;
          settings.PasswordAuthentication = false;
        };

        avahi = {
          enable = true;
          openFirewall = true; # UDP 5353
          publish = {
            enable = true;
            addresses = true;
            workstation = true;
          };
        };

        resolved = {
          enable = true;
          settings.Resolve.MultiCastDNS = "yes";
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        trustedInterfaces = [ "end0" "eth0" "en*" "wl*" "wlan*" ];
      };
    })

    # Extended Static Interface Networking
    (lib.mkIf (cfg.enable && cfg.enableStaticInterfaces) {
      networking = {
        useDHCP = false;
        useNetworkd = true;
        wireless.iwd = {
          enable = true;
          settings.Network = {
            EnableIPv6 = false;
            RoutePriorityOffset = 300; 
          };
        };
      };


      sops = {
        secrets."wifi_password" = lib.mkIf hasWifi {
          # Restrict permissions so only root/iwd can read it
          mode = "0600";
          owner = "root";
          group = "root";
        };

        # Generate the iwd PSK file securely using sops template
        templates."${wifiSsid}.psk" = lib.mkIf hasWifi {
          path = "/var/lib/iwd/${wifiSsid}.psk";
          owner = "root";
          group = "root";
          mode = "0600";
          content = ''
            [Security]
            Passphrase=${config.sops.placeholder."wifi_password"}
          '';
        };
      };

    # Ensure iwd waits for SOPS to render the file before starting
      systemd = {
        network = {
          enable = true;
          networks = {
            # Wired Ethernet
            "10-ethernet-static" = {
              matchConfig.Name = "en* eth* end*";
              networkConfig = {
                Address = [ "${fleetSettings.lan}/${subnetPrefix}" ];
                Gateway = networkSettings.gateway;
                DNS = networkSettings.dns;
              };
            };


            # Wireless Interface
            "20-wireless-static" = lib.mkIf hasWifi {
              matchConfig.Name = "wl* wlan*";
              networkConfig = {
                Address = [ "${fleetSettings.wifi}/${subnetPrefix}" ];
                Gateway = networkSettings.gateway;
                DNS = networkSettings.dns;
                IgnoreCarrierLoss = "3s";
              };
            };
          };
        };

        services = {
          iwd = lib.mkIf hasWifi {
            wants = [ "sops-nix.service" ];
            after = [ "sops-nix.service" ];
          };
          systemd-networkd-wait-online = {
            serviceConfig.ExecStart = [
              "" # Clear default binary arguments
              "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --any"
            ];
          };
        };
      };
    })
  ];
}
