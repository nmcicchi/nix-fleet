{ pkgs, ... }:

let
  vscodeExtensionsJson = ''
    {
      "recommendations": [
        "ms-python.python",
        "ms-python.vscode-pylance",
      ]
    }
  '';
in
{
  # Environment metadata / packages
  packages = with pkgs; [
    # Core CLI utilities
    git
    curl
  ];

  # Python & Data Science Environment
  languages.python = {
    enable = true;
    
    # Use Nix-packaged libraries for faster builds & total reproducibility
    libraries = with pkgs; [
      stdenv.cc.cc.lib
    ];

    # Installs Python packages directly via Nix
    package = pkgs.python3.withPackages (ps: with ps; [
      flake8
      pep8-naming
    ]);
  };

  # Custom shell startup message & workspace auto-configuration
  enterShell = ''
    # Create .envrc if it doesn't exist
    if [ ! -f .envrc ]; then
      echo "use flake" > .envrc
      echo "Created default .envrc file."
    fi

    # Create .vscode/extensions.json if it doesn't exist
    if [ ! -f .vscode/extensions.json ]; then
      mkdir -p .vscode
      cat << 'EOF' > .vscode/extensions.json
${vscodeExtensionsJson}EOF
      echo "Created .vscode/extensions.json workspace recommendations."
    fi

    echo " - VS Code: Select the Python interpreter/kernel from your Nix environment."
  '';
}
