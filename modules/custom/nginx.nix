{
  config,
  lib,
  fleetSettings,
  ...
}:
let
  cfg = config.my.reverseProxy;

  vhostSubmodule = lib.types.submodule (
    { name, ... }: {
      options = {
        enable = lib.mkEnableOption "Nginx reverse proxy vhost" // {
          default = false;
        };

        domain = lib.mkOption {
          type = lib.types.str;
          default = "${name}.home";
          description = "Virtual host domain name.";
        };

        targetHost = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Backend host or IP.";
        };

        targetPort = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = fleetSettings.sequoia.ports.${name} or null;
          description = "Backend TCP port. Defaults to fleetSettings.sequoia.ports.${name} will error if unavailable";
        };

        scheme = lib.mkOption {
          type = lib.types.str;
          default = "http";
          description = "Backend protocol scheme.";
        };

        websockets = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable WebSocket proxying on root location.";
        };

        extraProxyHeaders = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Pass explicit Host and X-Forwarded-* headers.";
        };

        extraLocations = lib.mkOption {
          type = lib.types.attrsOf lib.types.attrs;
          default = { };
          description = "Additional Nginx location blocks for this vhost.";
        };
      };
    }
  );

  mkProxyPass =
    name: v:
    let
      port =
        lib.throwIf (v.targetPort == null)
          "my.reverseProxy.vhosts.${name}: targetPort resolved to null (set targetPort explicitly or add fleetSettings.sequoia.ports.${name})"
          v.targetPort;
    in
    "${v.scheme}://${v.targetHost}:${toString port}";

  enabledVhosts = lib.filterAttrs (_: v: v.enable) cfg.vhosts;

  generatedVirtualHosts = lib.mapAttrs' (
    name: v:
    lib.nameValuePair v.domain {
      locations = {
        "/" = {
          proxyPass = mkProxyPass name v;
          proxyWebsockets = lib.mkIf v.websockets true;
          extraConfig = lib.mkIf v.extraProxyHeaders ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      }
      // v.extraLocations;
    }
  ) enabledVhosts;
in
{
  options.my.reverseProxy = {
    enable = lib.mkEnableOption "centralized Nginx reverse proxy aggregation" // {
      default = enabledVhosts != { };
    };

    vhosts = lib.mkOption {
      type = lib.types.attrsOf vhostSubmodule;
      default = { };
      description = "Reverse proxy virtual host definitions contributed by service modules.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = generatedVirtualHosts;
    };

    networking.firewall.allowedTCPPorts = [ fleetSettings.sequoia.ports.nginx ];
  };
}
