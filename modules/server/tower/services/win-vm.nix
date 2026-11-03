{ pkgs, ... }: {
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true; # TPM 2.0
    };
  };

  users.users.nic.extraGroups = [ "libvirtd" "qemu" ];

  # Required packages for SPICE display and USB redirection on the host
  environment.systemPackages = with pkgs; [
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    usbredir
    dnsmasq
  ];

  networking.firewall.trustedInterfaces = [ "virbr0" ];
}
