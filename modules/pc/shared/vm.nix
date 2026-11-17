{ pkgs, ... }:

{
  # Enable the GUI manager on your laptop
  programs.virt-manager.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    virt-viewer
    usbredir
    remmina
  ];
}
