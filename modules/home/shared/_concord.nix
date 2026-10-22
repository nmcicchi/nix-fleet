{ pkgs, lib, config, ... }: {
  home.packages = [ pkgs.unstable.concord ];

  # probably need to pass sops in hm?
  sops.secrets.discord_token = {
    owner = "nic";
  };

  xdg.configFile."concord/config.toml".text = lib.generators.toTOML {} {
    display = {
      image_protocol = "auto";
      disable_image_preview = false;
      show_avatars = true;
      show_images = true;
      media_playback = false;
      image_preview_quality = "balanced";
      attachment_viewer_quality = "original";
      animate_previews = "always";
      show_custom_emoji = true;
      circular_avatars = false;
      hour_format_24 = true;
    };
    composer.emojis_as_links = false;
    safety.enabled = true;
    presence.share_rich_presence = true;
    credentials.store = "auto";
    notifications.desktop_notifications = true;
    voice = {
      self_mute = false;
      self_deaf = false;
      allow_microphone_transmit = false;
      push_to_talk = false;
      push_to_talk_shortcut = "F8";
      noise_suppression = true;
      microphone_sensitivity = -30;
      microphone_volume = 100;
      voice_output_volume = 100;
    };
  };
}
