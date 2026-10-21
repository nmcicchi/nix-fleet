{ loadModules, ... }:
{
  imports = loadModules ./.;
  
  mySystem.networking.enable = true;
}
