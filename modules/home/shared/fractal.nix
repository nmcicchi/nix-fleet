{ pkgs, ... }:
{
  home.packages = [ pkgs.fractal ];

  # Fractal stores its session through the Secret Service API.
  # Drop this if the NixOS side already runs gnome-keyring.
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };
}
