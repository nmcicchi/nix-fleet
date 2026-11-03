{ pkgs, ... }: {
  # Enable KVM and Libvirt
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true; # TPM 2.0
      ovmf.enable = true;   # UEFI support
      ovmf.packages = [ pkgs.OVMFFull.fd ];
    };
  };

  # Enable virt-manager GUI frontend
  programs.virt-manager.enable = true;

  # Ensure your user has permissions to manage virtual machines
  users.users.nic.extraGroups = [ "libvirtd" ];

  # Required tools and guest agent utilities
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio # Provides stable paravirtualized drivers (NIC, disk, balloon) for Windows
    dnsmasq    # Required for the default virtual network DHCP/DNS
  ];

  # Networking for the default NAT bridge (virbr0)
  networking.firewall.trustedInterfaces = [ "virbr0" ];
}
