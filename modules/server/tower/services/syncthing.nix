_: {
services.mySyncthing = {
    enable = true;
    role = "hub";

    devices = {
      "laptop"  = { id = "JAZNVH6-Z6NKEJ5-PUBLTNA-QRJSJNP-L422CY2-D2BHXSW-KO43777-3KHLTAJ"; };
      "desktop" = { id = "BT7EKN4-4QDHKBG-QDKKO3Q-GROPYYG-DDWXXHO-EOUWHTJ-QO4IER6-PTZOJQP"; };
    };

    folders = {
      "School" = {
        path = "/home/Nic/school";
        devices = [ "laptop" "desktop" ];
        watch = true;
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "15552000"; # 180 days
          };
        };
      };
    };
  };
}
