{ fleetSettings, ... }: {
  services.fleet-adguard.enable = true;

  services.fleet-keepalived = {
    enable = true;
    virtualIp = fleetSettings.network.adguard;   # The floating IP clients will use for DNS
    interface = "bro0";
    role = "MASTER";
    priority = 101;
  };
}
