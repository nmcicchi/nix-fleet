{ pkgs, ... }: {
  packages = with pkgs; [
    # Wine with 32-bit and 64-bit application support
    wineWow64Packages.stable

    # Windows dependency installer
    winetricks

    # Supporting utilities
    cabextract
    unzip
    p7zip
  ];

  # Configure a persistent Wine environment
  enterShell = ''
    export WINEPREFIX="$DEVENV_ROOT/wine/prefix"
    export WINEARCH=win64

    mkdir -p "$WINEPREFIX"
    mkdir -p "$DEVENV_ROOT/installers"
    mkdir -p "$DEVENV_ROOT/projects"

    echo "Machine Expert Basic development environment"
    echo "Wine prefix: $WINEPREFIX"
  '';

  # Initialize Wine for the first time
  scripts.wine-init.exec = ''
    wineboot --init
    winecfg
  '';

  # Run a Windows installer
  scripts.wine-installer.exec = ''
    if [ "$#" -ne 1 ]; then
      echo "Usage: wine-installer <installer.exe>"
      exit 1
    fi

    wine "$1"
  '';

  # Run an installed Windows application
  scripts.wine-run.exec = ''
    if [ "$#" -lt 1 ]; then
      echo "Usage: wine-run <application.exe> [arguments]"
      exit 1
    fi

    exe="$1"
    shift

    wine "$exe" "$@"
  '';

  # Inspect installed Winetricks dependencies
  scripts.wine-deps.exec = ''
    winetricks list-installed
  '';
}

