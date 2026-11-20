_: {
  # Enable Sunshine service
  services.sunshine = {
    enable = true;
    autoStart = true; # Starts as a systemd user service on graphical login
    capSysAdmin = true; # Required for Wayland capture
    openFirewall = true; # Opens standard TCP/UDP streaming ports
  };

  # Allow Sunshine to emulate mouse, keyboard, and gamepad inputs
  hardware.uinput.enable = true;
  users.users.nic.extraGroups = [
    "uinput"
    "input"
  ];

  # Optional: Required only if you plan to pass through DualShock/DualSense controllers
  services.udev.extraRules = ''
    KERNEL=="uhid", GROUP="input", MODE="0660", OPTIONS+="static_node=uhid", TAG+="uaccess"
  '';

  # enables wake on lan, must be enabled in bios
  #networking.interfaces.<iface>.wakeOnLan.enable = true;

  # Optional: If streaming over Tailscale, trust the interface so Tailscale traffic isn't blocked
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
