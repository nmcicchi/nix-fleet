{ pkgs, fleetSettings, lib, ... }: 

let
  # for tmp hash use lib.fakeHash
  mods26-1 = [
    (pkgs.fetchurl {
      name = "ferritecore-9.0.0-fabric.jar";
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/d5ddUdiB/ferritecore-9.0.0-fabric.jar?mr_download_reason=standalone";
      sha256 = "sha256-ITlmxy7ZZ6zHOSvrKKhm+6MB/1a5l2wueAHC233mvyI=";
    })
    (pkgs.fetchurl {
      name = "Chunky-Fabric-1.5.3.jar";
      url = "https://cdn.modrinth.com/data/fALzjamp/versions/4Eotm6ov/Chunky-Fabric-1.5.3.jar";
      sha256 = "sha256-7N/FWg9n8+xvQIUGh2FclBriJr2I9OBhiKeyaP09qUI=";
    })
    (pkgs.fetchurl {
      name = "servercore-fabric-1.5.20%2B26.3.jar";
      url = "https://cdn.modrinth.com/data/4WWQxlQP/versions/LCG1Bm84/servercore-fabric-1.5.20%2B26.3.jar";
      sha256 = "sha256-YvunwseRW3P2ivnPo6YWRz3ViGXcXCE7Rt3WeLGqkGU=";
    })
    (pkgs.fetchurl {
      name = "krypton-0.3.2.jar";
      url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/UugdIYJw/krypton-0.3.2.jar";
      sha256 = "sha256-C0pki5wvBIJH+ElxKv9YsrrFsntgwAcrtr9JOti3n+8=";
    })
  ];

in 
{
  services.minecraft-instances = {
    "minecraft-26" = {
      enable = true;
      tsContainerName = "mc-ts";
      mcIp = fleetSettings.sequoia.containers.mc-26.lan;
      tsIp = fleetSettings.sequoia.containers.mc-26.router;
      mods = mods26-1;
      
      environment = {
        version = "26.3";
        memory = "12G";
        viewDistance = 16;
        simulationDistance = 8;
        difficulty = "normal";
      };
    };

    # Example of a toggled-off server that will not deploy
    "minecraft-vanilla" = {
      enable = false;
      tsContainerName = "vanilla-ts";
      mcIp = "192.168.5.105";
      tsIp = "192.168.5.106";
      mods = [ ];
      
      environment = {
        version = "26.1.2"; # whatever the latest version is
        memory = "4G";
      };
    };
  };
}
