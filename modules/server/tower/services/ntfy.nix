{ config, fleetSettings, ... }:
{
  sops.secrets."ntfy-server-env" = { };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.home";
      listen-http = "127.0.0.1:${toString fleetSettings.sequoia.ports.ntfy}";
      behind-proxy = true;
      cache-file = "/var/lib/ntfy-sh/cache.db";
      auth-file = "/var/lib/ntfy-sh/user.db";
      auth-default-access = "deny-all";
      enable-signup = false;
      auth-access = [
        "*:up*:write-only"
        "matrix-client:up*:read-only"
      ];
    };
  };

  systemd.services.ntfy-sh.serviceConfig.EnvironmentFile = config.sops.secrets."ntfy-server-env".path;

  my.reverseProxy.vhosts.ntfy = {
    enable = true;
    websockets = true;
  };
}
