_: {
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/log"            # Systemd journal logs
      "/var/lib/nixos"      # Keeps UID/GID allocations consistent
      "/var/lib/systemd"    # Systemd state and timers
      "var/lib/tailscale-mc-26"
      "/var/lib/tailscale"
    ];

    files = [
      "/etc/machine-id"                # Essential for network leases & systemd logs
      "/etc/ssh/ssh_host_ed25519_key"  # Prevents SSH host key regeneration
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
