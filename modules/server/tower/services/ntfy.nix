_: {
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.yourdomain.com";
      listen-http = "127.0.0.1:2586";
      behind-proxy = true;
      cache-file = "/var/lib/ntfy-sh/cache.db";
      auth-file = "/var/lib/ntfy-sh/user.db";
      auth-default-access = "deny-all";
      enable-signup = false;
      # Allow unauthenticated pushers to publish to UnifiedPush/Matrix topics (up*),
      # while keeping reads locked down to authenticated users/tokens.
      auth-access = [
        "*:up*:write-only"
        "matrix-laptop:up*:read-only"
      ];
    };
  };

  # I like this self contained version its very cool
  my.reverseProxy.vhosts.ntfy = {
    enable = true;
    websockets = true; # useful for live SSE/WebSocket topic streaming
  };
}
