{ config, lib, modulesPath, ... }: {
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "nvme" "usb_storage" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Supermicro ASPEED BMC framebuffer fix to prevent EFI boot crashes
  boot.kernelParams = [
    "console=tty0"
    # "panic=10"
    # "nomodeset"
    # "video=efifb:off"
    # "initcall_blacklist=sysfb_init"
  ];

  # Root mapped to RAM (tmpfs)
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "defaults" "size=16G" "mode=755" ];
  };

  # Ext4 root drive mapped to /persist
  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/d0555a94-cf8f-4d6d-8cff-45ec4ee57abf";
    fsType = "ext4";
    neededForBoot = true; # CRITICAL: ensures /persist mounts in stage 1
  };

  # Persistent Nix Store bind-mounted from /persist
  # (CRITICAL: Prevents 16GB RAM overflow from nix store allocations)
  fileSystems."/nix" = {
    device = "/persist/nix";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
  };

  # EFI Boot Partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B41B-EF9A";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
