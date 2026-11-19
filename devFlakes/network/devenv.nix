{ pkgs, ... }:

{
  packages = with pkgs; [
    wireshark-cli # provides tshark
    (python3.withPackages (ps: with ps; [
      scapy
    ]))
  ];

  scripts.plc-capture = {
    description = "Stream EtherNet/IP traffic from a remote host over SSH and format human-readable summaries";
    exec = ''
      exec "${./scripts/plc-capture.sh}" "$@"
    '';
  };
}
