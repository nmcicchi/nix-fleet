{ pkgs, ... }: {
  packages = with pkgs; [
    # Parametric CAD
    openscad

    # CLI mesh validator
    admesh
    # 3D printing slicer
    prusa-slicer
  ];

  enterShell = ''
    echo "OpenSCAD development environment"
    echo "OpenSCAD: $(openscad --version)"
    echo ""
    echo "Launch OpenSCAD: openscad"
    echo "Launch PrusaSlicer: prusa-slicer"
  '';
}
