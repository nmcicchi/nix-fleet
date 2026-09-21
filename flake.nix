{
  description = "My NixOS system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    impermanence.url = "github:nix-community/impermanence";

    silentSDDM = {
      url="github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    monique = {
      url = "github:ToRvaLDz/monique";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
   
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nvf,
    home-manager,
    nur,
    ...
  }@inputs: let

    # a function for creating nvf
    nvfFN = systemPkgs: 
      (nvf.lib.neovimConfiguration {
        pkgs = systemPkgs;
        modules = [./nvf/nvf-configuration.nix];
      }).neovim;

    mkHost = import ./lib/mkHost.nix;

    mkHome = import ./lib/mkHome.nix { inherit home-manager; };

  in {
    templates = {
      # initialize a devenv with
      # nix flake init -t ~/nix-fleet#java
      # devenv direnvrc
      # direnv allow
      # devenv shell
      java = {
        path = ./devFlakes/java;
        description = "CS Java Dev Environment with devenv, direnv, and Checkstyle";
      };
      jupyter = {
        path = ./devFlakes/jupyter;
        description = "Jupyter dev environment with devenv, and direnv";
      };
    };

    nixosConfigurations = {
      installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/iso.nix
        ];
        specialArgs = { inherit inputs; };
      };

      lotus = mkHost {
        hostname = "lotus";
        system = "x86_64-linux";
        pkgsInput = nixpkgs;
        overlays = [
            (import ./overlays/flameshot.nix)
            (import ./overlays/qutebrowser.nix)
            (import ./overlays/steam.nix)
            (import ./overlays/unstable.nix { inherit nixpkgs-unstable; } )
        ];
        modules = [
          ./modules/pc/laptop
          ./modules/pc/shared
          inputs.nix-flatpak.nixosModules.nix-flatpak
          inputs.silentSDDM.nixosModules.default
          inputs.sops-nix.nixosModules.default
          inputs.monique.nixosModules.default
        ];
        extraSpecialArgs = { 
          inherit nvfFN;
        };
      };

      cedar = mkHost {
        hostname = "cedar";
        system = "x86_64-linux";
        pkgsInput = nixpkgs;
        overlays = [
          (import ./overlays/unstable.nix { inherit nixpkgs-unstable; } )
        ];
        modules = [
          ./modules/pc/shared
          ./modules/pc/desktop
          inputs.nix-flatpak.nixosModules.nix-flatpak
          inputs.sops-nix.nixosModules.default
          inputs.monique.nixosModules.default
          inputs.silentSDDM.nixosModules.default
        ];
        extraSpecialArgs = { 
          inherit nvfFN;
        };
      };

      sequoia = mkHost {
        hostname = "sequoia";
        routing = true;
        system = "x86_64-linux";
        pkgsInput = nixpkgs;
        modules = [
          ./modules/server/tower
          inputs.sops-nix.nixosModules.default
          inputs.disko.nixosModules.default
          inputs.arion.nixosModules.arion
          inputs.impermanence.nixosModules.impermanence
        ];
        overlays = [
          (import ./overlays/unstable.nix { inherit nixpkgs-unstable; } )
        ];
      };

      juniper = mkHost {
        hostname = "juniper";
        system = "aarch64-linux";
        pkgsInput = nixpkgs;
        modules = [
          ./modules/server/assistant
          inputs.sops-nix.nixosModules.default

          # makes it so can build sd images
          ({ modulesPath, ... }: {
            imports = [
              "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
            ];
          })
        ];
      };

      rowan = mkHost {
        hostname = "rowan";
        system = "aarch64-linux";
        pkgsInput = nixpkgs-unstable;
        modules = [
          ./modules/server/dashboard
          inputs.sops-nix.nixosModules.default
          inputs.nixos-hardware.nixosModules.raspberry-pi-5
        ];
      };

      aspen = mkHost {
        hostname = "aspen";
        system = "x86_64-linux";
        pkgsInput = nixpkgs;
        cudaSupport = true;
        modules = [
            ./modules/server/ai
            inputs.sops-nix.nixosModules.default
        ];
      };
    };

    homeConfigurations = builtins.mapAttrs (target: config: mkHome target config) {
      "nic@lotus" = {
        pkgs = self.nixosConfigurations.lotus.pkgs;
        modules = [
          ./modules/home/lotus
          ./modules/home/shared
          inputs.niri.homeModules.niri
          inputs.zen-browser.homeModules.twilight
        ];
        extraSpecialArgs = { inherit nur; };
      };

      "nic@cedar" = {
        pkgs = self.nixosConfigurations.cedar.pkgs;
        modules = [
          ./modules/home/shared
          ./modules/home/cedar
          inputs.niri.homeModules.niri
          inputs.zen-browser.homeModules.twilight
        ];
        extraSpecialArgs = { inherit nur; };
      };
    };
  };
}
