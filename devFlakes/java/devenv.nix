{ pkgs, ... }:

let
  vscodeExtensionsJson = ''
    {
      "recommendations": [
        "vscjava.vscode-java-pack",
        "shengchen.vscode-checkstyle"
      ]
    }
  '';
in
{
  languages = {
    java = {
      enable = true;
      jdk.package = pkgs.jdk21;
    };
    python = {
      enable = true;
      package = pkgs.python3.withPackages (ps: with ps; [
        pandas
        plotly
        jupyter
        ipykernel
      ]);
    };
  };

  env = {
    CHECKSTYLE_CONFIG = "${toString ./.}/checkstyle.xml";
    NIX_CFLAGS_COMPILE = "-Wno-error"; # Standard way to set compile flags in devenv
  };

  # this is an attempt to get jupyter without an auth token
  # idk that it worked tho...
  scripts = {
    lab.exec = ''
     jupyter lab --port=8888 --no-browser --ServerApp.token= --ServerApp.password=
    '';
  };

  enterShell = ''
    # Create .vscode/extensions.json if it doesn't exist
    if [ ! -f .vscode/extensions.json ]; then
      mkdir -p .vscode
      cat << 'EOF' > .vscode/extensions.json
${vscodeExtensionsJson}EOF
      echo "Created .vscode/extensions.json workspace recommendations."
    fi

    echo "☕ Java Development Shell Ready"
    echo "JDK: $(java -version 2>&1 | head -n 1)"
  '';
}
