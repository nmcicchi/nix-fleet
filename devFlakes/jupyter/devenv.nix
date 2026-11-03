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
in {
  packages = with pkgs; [
    git
    curl
    python312
    uv
    stdenv.cc.cc.lib # Provides libstdc++.so.6 for PyPI binary wheels
  ];

  # Expose standard C++ libraries to unpatched binaries/wheels
  env.LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";

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

  enterShell = ''
    # Automatically create a local virtual environment and sync packages using uv
    if [ ! -d .venv ]; then
      uv venv
    fi
    source .venv/bin/activate
    
    # Create .vscode/extensions.json if it doesn't exist
    if [ ! -f .vscode/extensions.json ]; then
      mkdir -p .vscode
      cat << 'EOF' > .vscode/extensions.json
${vscodeExtensionsJson}EOF
      echo "Created .vscode/extensions.json workspace recommendations."
    fi

    # Fast install from pre-compiled PyPI binary wheels
    uv pip install jupyterlab ipykernel pandas numpy matplotlib plotly
    
    echo "Python virtual environment ready via uv (pre-compiled wheels)!"
  '';
}
