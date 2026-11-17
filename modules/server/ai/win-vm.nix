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

  environment.persistence."/persistent" = {
    directories = [
      "/etc/libvirt"
      "/var/lib/libvirt"
    ];
  };

  # Creates a dedicated bridge for the plc that does not touch the host os or get an ip on the lan
  networking.bridges = {
    plc-br.interfaces = [ "eno2" ]; # Dedicated physical port for plc
  };
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    ""
    "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --ignored=plc-br"
  ];
  # Commands to start virtual net
  # sudo virsh net-start default
  # sudo virsh net-autostart default

  # Commands to remove virtual net
  # sudo virsh net-destroy default
  # sudo virsh net-undefine default
}
