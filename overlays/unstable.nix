{ nixpkgs-unstable }:

final: prev: {
  unstable = import nixpkgs-unstable {
    system = prev.stdenv.hostPlatform.system;

    config = {
      allowUnfree = true;
      permittedInsecurePackages = prev.config.permittedInsecurePackages or [ ];
    };

    overlays = [
      #(import ./python-pin.nix)
    ];
  };
}
