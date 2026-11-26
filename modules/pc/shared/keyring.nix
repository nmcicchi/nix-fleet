_: {
  services.gnome.gnome-keyring.enable = true;

  # unlocks the keyring with your login password at SDDM login
  security.pam.services.sddm.enableGnomeKeyring = true;

  # optional GUI for managing keyrings, useful for debugging
  programs.seahorse.enable = true;
}
