{ self }:
{
  hostname,
  routing ? false,
  system,
  overlays ? [ ],
  cudaSupport ? false,
  allowUnfree ? true,
  modules,
  extraSpecialArgs ? { },
  pkgsInput,
}:
let
  fleetSettings = import ../fleet-settings.nix;
in
pkgsInput.lib.nixosSystem {
  inherit system;

  pkgs = import pkgsInput {
    inherit system overlays;
    config = {
      inherit cudaSupport allowUnfree;
      # from matrix-whatsapp
      permittedInsecurePackages = fleetSettings.${hostname}.permittedInsecurePackages or [ ];
    };
  };

  modules = [
    ../modules/shared
    ../modules/custom
  ]
  ++ modules;

  specialArgs = {
    inherit hostname self;

    fleetSettings = if routing then fleetSettings else fleetSettings.${hostname} or { };

    networkSettings = fleetSettings.network;

    loadModules = import ./load-modules.nix { inherit (pkgsInput) lib; };
  }
  // extraSpecialArgs;
}
