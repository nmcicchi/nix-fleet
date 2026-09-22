{ config, lib, hostname, fleetSettings ? null, ... }:

with lib;

let
  cfg = config.services.mySyncthing;
  username = "nic";
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
          ignorePatterns = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of .stignore patterns";
          };
        };
      });
      default = {};
      description = "Folders managed by Syncthing on this host.";
    };
  };

  config = mkIf cfg.enable {
  sops = {
    secrets = {
      "syncthing/${hostname}/cert" = {
          owner = username;
          group = "users";
        };
      "syncthing/${hostname}/key"  = {
          owner = username;
          group = "users";
        };
    };
    # This has to be dumb
    templates = {
      "syncthing-${hostname}-cert" = {
        content = config.sops.placeholder."syncthing/${hostname}/cert";
        owner = "nic";
        group = "users";
        mode = "0600";
      };
      "syncthing-${hostname}-key" = {
        content = config.sops.placeholder."syncthing/${hostname}/key";
        owner = "nic";
        group = "users";
        mode = "0600";
      };
    };
  };
     systemd.services.syncthing = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
      #stopIfChanged = false;
    };

    systemd.services.syncthing-init = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
      #stopIfChanged = false;
    };

    services.syncthing = {
      enable = true;
      user = username;
      dataDir = "/home/${username}";
      configDir = "/home/${username}/.config/syncthing";

      cert = config.sops.templates."syncthing-${hostname}-cert".path;
      key  = config.sops.templates."syncthing-${hostname}-key".path;

      overrideFolders = true;
      overrideDevices = true;

      settings = {
        inherit (cfg) devices;
        gui = {
          enabled = true;
          address = "127.0.0.1:8384";
        };

        folders = mapAttrs (_name: folderCfg: {
          inherit (folderCfg) path devices versioning ignorePatterns;
          fsWatcherEnabled = folderCfg.watch;
        }) cfg.folders;
      };
    };

    networking.firewall.allowedTCPPorts = if cfg.role == "hub" && fleetSettings != null
      then [ fleetSettings.sequoia.ports.syncthing ]
      else [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
