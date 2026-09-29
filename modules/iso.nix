{ pkgs, modulesPath, ... }:

{
  imports = [
    # Import standard minimal NixOS ISO base
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader & kernel console settings for headless / IPMI / Serial compatibility
  boot = {
    kernelParams = [ "nomodeset" "console=tty0" "console=ttyS0,115200n8" ];
    loader.grub.gfxmodeEfi = "text";
    zfs.forceImportRoot = false;
  };

  # Network & Host configuration
  networking.hostName = "nixos-installer";
  # networking.wireless.enable = false; # Avoid conflicts with NetworkManager / wpa_supplicant

  # Enable OpenSSH server for remote provisioning
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Essential CLI packages for manual or scripted system setup
  environment.systemPackages = with pkgs; [
    git
    neovim
    curl
    wget
    tmux
    htop
    pciutils
    usbutils
    jq
    rsync
    parted
    disko # Helpful if using Disko for automated disk partitioning
  ];

  # User setup
  users.users.nic = {
    isNormalUser = true;
    description = "nic";
    extraGroups = [ "wheel" "dialout" ];
    shell = pkgs.zsh;
    password = "please";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwVDpKO0Stfm4abOjFjSBT0LbVJdwJJsqp7iOc9mzMI"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHu4MMLoTG4QET3RbY5tvJrtWDO0tN+58NH/OVZ5b3mo"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMImsuLVN/U9zBaMFNKNqVP5AtMu9UEDM+xxhHk21anNAAAADXNzaDpuaXgtZmxlZXQ="
    ];
  };

  programs.zsh.enable = true;

  nix.settings.trusted-users = [ "root" "nic" ];


  # Allow passwordless sudo for wheel group to make bootstrapping easy
  security.sudo.wheelNeedsPassword = false;

  # Speed up image compilation
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
}
