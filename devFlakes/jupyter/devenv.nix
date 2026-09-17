{ pkgs, ... }:

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
    # Run `lab` to launch Jupyter Lab on port 8888
    lab.exec = ''
      jupyter lab --port=8888 --no-browser
    '';
    
    # Run `nb-clean` to strip notebook output before git commits
    nb-clean.exec = ''
      jupyter nbconvert --clear-output --inplace *.ipynb
    '';
  };

  # Custom shell startup message
  enterShell = ''
    echo " Reusable Jupyter Data Science Shell Ready!"
    echo " - Run 'lab' to launch JupyterLab"
    echo " - Run 'nb-clean' to clear outputs before committing"
  '';
}
