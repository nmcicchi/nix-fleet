{ pkgs, ... }: {
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    rocmOverrideGfx = "10.3.0"; 
  };

  services.open-webui = {
    enable = true;
    port = 8080;
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "False"; 
    };
  };

  environment.systemPackages = with pkgs; [
    aider-chat 
  ];
}
