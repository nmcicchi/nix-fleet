{ name, uid, subStart, subCount ? 65536 }: {
  users.groups.${name} = {};
  users.users.${name} = {
    isNormalUser = true;
    inherit uid;
    group = name;
    linger = true;
    subUidRanges = [{ startUid = subStart; count = subCount; }];
    subGidRanges = [{ startGid = subStart; count = subCount; }];
  };

  environment.persistence."/persist" = {
    directories = [
      { directory = "/home/${name}"; user = name; group = name; mode = "0700"; }
    ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
