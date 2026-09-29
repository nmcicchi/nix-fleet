_:{
  nix.settings = {
    # Keep trusted-users restricted to root
    trusted-users = [ "root" ];

    # Globally allow these caches so any user can pull from them safely
    substituters = [
      "https://cache.nixos.org" # Default
      "https://nix-community.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://nixos-raspberrypi.cachix.org"
    ];

    # Explicitly trust the corresponding public keys
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" # Default
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };
}
