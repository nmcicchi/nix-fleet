_: {
  services.mySyncthing = {
    enable = true;
    role = "client";

    devices = {
      "server" = { id = "NC2GPIP-COQZ7DN-2BXD22Y-6MHGGSF-7JLIMM6-STS6ZYM-SFYZ6WC-6VBPJQH"; };
    };

    folders = {
      "School" = {
        path = "/home/Nic/school";
        devices = [ "server" ];
        watch = true;
      };
    };
  };
}
