{
  pkgs,
  nvfFN,
  ...
}:
let
  stable = with pkgs; [
    mpv # terminal video player
    yt-dlp # yt vid downloader
    streamlink # way to watch twitch ad free sorta
    gnumake
    imv
    exiftool # idk what this is
    evtest # or this
    wireshark # network traffic monitor
    dig
    kanshi # todo list
    ffmpeg
    xdg-utils
    localsend # file transfer thing
    file # this isnt included by default?
    clamav # idk what this is
    poppler-utils
    kdePackages.okular # pdf editor
    imagemagick # actual magic
    qalculate-qt # calculator
    fd
    nmap
    moonlight-qt # remote gaming viewer
  ];

  unstable = with pkgs.unstable; [
  ];

  nvfPkg = nvfFN pkgs.unstable;

in
{
  environment.systemPackages = stable ++ unstable ++ [ nvfPkg ];
}
