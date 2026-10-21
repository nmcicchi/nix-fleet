{pkgs, ...}: {
  environment.systemPackges = with pkgs; [
    concord
    watui
  ];
}
