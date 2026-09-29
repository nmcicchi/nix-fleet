{ loadModules, ... }:
{
  imports = loadModules ./.;

  # binary cache for pi 5 kernel, all builders will need this in their config
  nix.settings = {
    substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  boot.loader.raspberry-pi.bootloader = "kernel";

  boot.zfs.forceImportRoot = false;
}
