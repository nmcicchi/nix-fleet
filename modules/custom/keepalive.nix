{ config, lib, ... }: let
  cfg = config.services.fleet-keepalived;
in
{
  options.services.fleet-keepalived = {
    enable = lib.mkEnableOption "Fleet-managed Keepalived VRRP high-availability failover";

    virtualIp = lib.mkOption {
      type = lib.types.str;
      description = "The floating Virtual IP (VIP) shared between your high-availability nodes.";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = "The network interface name used for VRRP heartbeats.";
    };

    role = lib.mkOption {
      type = lib.types.enum [ "MASTER" "BACKUP" ];
      default = "BACKUP";
      description = "The initial VRRP state/role of this node.";
    };

    priority = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "VRRP priority score. The node with the higher priority becomes MASTER.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.keepalived = {
      enable = true;
      # uses IP Protocal 12 instead of udp or tcp
      openFirewall = true;
      vrrpInstances.ha_gateway = {
        inherit (cfg) interface role priority;
        state = cfg.role;
        virtualRouterId = 51; # Must match across all nodes sharing this VIP
        virtualIps = [
          { addr = cfg.virtualIp; }
        ];
      };
    };
  };
}
