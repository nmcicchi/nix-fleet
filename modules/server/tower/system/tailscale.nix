{fleetSettings, ...}: {
  services.tailscale.extraUpFlags = [
  "--advertise-routes=${fleetSettings.sequoia.lan}"
  ];
}
