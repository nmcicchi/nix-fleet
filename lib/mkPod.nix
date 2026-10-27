{ name, uid, subStart, subCount ? 65536 }:
{ config, lib, ... }:
let
  uidStr = toString uid;
  runtimeDir = "user-runtime-dir@${uidStr}.service";

  # Every oci-container that runs as this pod's rootless user
  containers = lib.filterAttrs
    (_: c: c.podman.user == name)
    config.virtualisation.oci-containers.containers;
in {
  users.groups.${name} = {};
  users.users.${name} = {
    isNormalUser = true;
    inherit uid;
    group = name;
    linger = true; # keep /run/user/<uid> alive without a login session
    subUidRanges = [{ startUid = subStart; count = subCount; }];
    subGidRanges = [{ startGid = subStart; count = subCount; }];
  };

  environment.persistence."/persist" = {
    directories = [
      # rootless podman image/container storage lives here
      { directory = "/home/${name}"; user = name; group = name; mode = "0700"; }
    ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Make every rootless container unit wait for the user's runtime dir, and
  # give podman what it needs from a system service: XDG_RUNTIME_DIR and the
  # setuid newuidmap/newgidmap wrappers.
  systemd.services = lib.mapAttrs' (cname: _:
    lib.nameValuePair "podman-${cname}" {
      requires = [ runtimeDir ];
      after = [ runtimeDir ];
      environment.XDG_RUNTIME_DIR = lib.mkDefault "/run/user/${uidStr}";
      path = [ "/run/wrappers" ];
    }
  ) containers;
}
