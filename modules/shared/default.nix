{ loadModules, hostname, pkgs, ... }:
{
  imports = loadModules ./.;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  
  networking.hostName = hostname;

  system.stateVersion = "25.05";

  time.timeZone = "America/New_York";

  # Sets default editor
  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    systemPackages = [ pkgs.neovim ];
  };

  # temp fix for CA vulnerability
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];
}
