{ loadModules, lib, pkgs, ... }:
{
  imports = loadModules ./.;

  # Force a cached rpi kernel to bypass local compilation
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_rpi4;
}
