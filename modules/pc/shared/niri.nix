{ pkgs, ... }: {
  programs = {
    gamescope.enable = true;
    monique.enable = true;
  };

  # PipeWire is required for Wayland screencast buffer transport
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  xdg.portal = {
    enable = true;
    configPackages = [ pkgs.niri ];

    config = {
      niri = {
        default = [ "gnome" "gtk" ]; # Routes Screencast and Screenshot to GNOME portal
        "org.freedesktop.impl.portal.FileChooser" = [
          "termfilechooser"
          "gnome"
          "gtk"
        ];

        # Route dark mode, font, and accent colors to gtk
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };

    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xdg-desktop-portal-termfilechooser
    ];
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    nautilus
  ];
}
