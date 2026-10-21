{ loadModules, ... }: {
  imports = loadModules ./.;
  
  mySystem.networking = {
    enable = true;
    enableStaticInterfaces = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

}
