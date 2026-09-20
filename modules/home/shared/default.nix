{ loadModules, ... }:
{
  imports = loadModules ./.;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "nmcicchi";
        email = "nmcicchi@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };
}
