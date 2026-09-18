{ pkgs, ... }:

let
  vscodeExtensionsJson = ''
    {
      "recommendations": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-toolsai.jupyter",
        "ms-toolsai.vscode-jupyter-cell-tags",
        "ms-toolsai.jupyter-renderers"
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
      # Core Jupyter tools
      jupyterlab
      ipykernel

      # Data Analysis & Science
      pandas
      numpy

      # Visualization
      matplotlib
      plotly
    ]);
  };

  # Helper commands executable inside `devenv shell`
  scripts = {
    # Run `lab` to launch Jupyter Lab on port 8888 (browser fallback)
    lab.exec = ''
      jupyter lab --port=8888 --no-browser
    '';
    
    # Run `nb-clean` to strip notebook output before git commits
    nb-clean.exec = ''
      jupyter nbconvert --clear-output --inplace *.ipynb
    '';
  };

  # IDK if this is the best way to do it
  # but to connect to the kernel from vscode select "select another kernel"
  # existing jupyter server
  # then put in the url output by the "lab" command in this devenv

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

    echo "Python & Jupyter VS Code Development Shell Ready!"
    echo " - VS Code: Select the Python interpreter/kernel from your Nix environment."
    echo " - Terminal fallback: Run 'lab' to launch browser JupyterLab."
    echo " - Run 'nb-clean' to clear outputs before committing."
  '';
}
