{ pkgs, ...}: {
  home.packages = with pkgs; [ watui ];
}
