{ loadModules, lib, ... }:
{
  imports = loadModules ./.;

  # bootloader stuff
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = lib.mkForce false;

  # hardware settings
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];
  sdImage.compressImage = false;
}
