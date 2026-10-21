{ fleetSettings, ... }: {
  services.fleet-adguard.enable = true;

  services.fleet-keepalived = {
    enable = true;
    virtualIp = fleetSettings.network.adguard;   # The floating IP clients will use for DNS
    interface = "eth0";
    role = "BACKUP";
    priority = 102;
  };
}
