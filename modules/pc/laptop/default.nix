{ loadModules, ... }:
{
  imports = loadModules ./.;
  swapDevices = [
    {
      device = "/swapfile";
      size = 8 * 1024;
    }
  ];

  services.hardware.bolt.enable = true;
}
