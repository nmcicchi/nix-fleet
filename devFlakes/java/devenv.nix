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
  languages.java = {
    enable = true;
    jdk.package = pkgs.jdk21;
  };

  env = {
    #JAVA_HOME = lib.mkForce "${pkgs.jdk21}";
    CHECKSTYLE_CONFIG = "${toString ./.}/checkstyle.xml";
    NIX_CFLAGS_COMPILE = "-Wno-error"; # Standard way to set compile flags in devenv
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
