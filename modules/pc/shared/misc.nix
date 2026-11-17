{ pkgs, ... }: {
  programs = {
    dconf.enable = true;
  };

  # Sets kernel to zen kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Configure boot menu
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # enable binfmt with qemu for building aarch64 images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Enable PCSC daemon for YubiKey smart card support
  services.pcscd.enable = true;

  security.polkit.enable = true;

  # enable nix-ld to use vscode extensions from code store
  programs.nix-ld = {
    enable = true;

    # Add common libraries unpatched binaries (like VS Code extensions) often expect
    libraries = with pkgs; [
      zlib
      zstd
      stdenv.cc.cc
      curl
      openssl
      glib
      util-linux
    ];
  };
}
