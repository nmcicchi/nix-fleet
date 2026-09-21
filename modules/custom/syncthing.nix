{ config, lib, hostname, fleetSetting ? null, ... }:

with lib;

let
  cfg = config.services.mySyncthing;
  username = "Nic";
in
{
  options.services.mySyncthing = {
    enable = mkEnableOption "custom Syncthing service";

    role = mkOption {
      type = types.enum [ "client" "hub" ];
      default = "client";
      description = "Determines firewall port defaults and topology role.";
    };

    # Hosts explicitly declare connected devices
    devices = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          id = mkOption { type = types.str; description = "Syncthing Device ID"; };
          addresses = mkOption { 
            type = types.listOf types.str; 
            default = [ "dynamic" ]; 
            description = "Optional explicit IP/DNS addresses for this device";
          };
        };
      });
      default = {};
      description = "Attribute set of devices and their Device IDs for this host.";
    };

    # Hosts explicitly declare synced folders (Defaults to empty)
    folders = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          path = mkOption { type = types.str; description = "Local folder path"; };
          devices = mkOption { type = types.listOf types.str; description = "Devices to sync this folder with"; };
          watch = mkOption { type = types.bool; default = true; description = "Enable filesystem watching"; };
          versioning = mkOption { type = types.nullOr types.attrs; default = null; description = "Versioning strategy"; };
        };
      });
      default = {};
      description = "Folders managed by Syncthing on this host.";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "syncthing/${hostname}/cert" = { owner = username; group = "users"; };
      "syncthing/${hostname}/key"  = { owner = username; group = "users"; };
    };

    services.syncthing = {
      enable = true;
      user = username;
      dataDir = "/home/${username}";
      configDir = "/home/${username}/.config/syncthing";

      cert = config.sops.secrets."syncthing/${hostname}/cert".path;
      key  = config.sops.secrets."syncthing/${hostname}/key".path;

      overrideFolders = true;
      overrideDevices = true;

      settings = {
        gui.enabled = false;
        devices = cfg.devices;
        folders = cfg.folders;
      };
    };

    networking.firewall.allowedTCPPorts = if cfg.role == "hub" && fleetSetting != null
      then [ fleetSetting.sequoia.ports.syncthing ]
      else [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
