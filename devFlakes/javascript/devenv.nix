{ pkgs, ... }: {
  languages.javascript = {
    enable = true;
    eslint.enable = true;
  };

  packages = with pkgs; [
    nodePackages.eslint
  ];

  env = {
    CHECKSTYLE_CONFIG = "${toString ./.}/checkstyle.xml";
  };

  enterShell = ''
    echo "JavaScript Development Shell Ready"
    echo "JS: $(javascript -version 2>&1 | head -n 1)"
  '';
}
