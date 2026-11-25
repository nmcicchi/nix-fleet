_: {
  programs.nheko = {
    enable = true;
    settings = {
      user = {
        alertOnNotification = true;
        animateImagesOnHover = false;
        markdown = true;
        typingNotifications = true;
        readReceipts = true;
        desktopNotifications = true;
        privacyScreen = false;
      };
      sidebar = {
        roomListWidth = 300;
      };
    };
  };
}
