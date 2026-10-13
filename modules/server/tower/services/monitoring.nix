{ pkgs, fleetSettings, config, lib, ... }: {
  # glances for system metrics
  services.glances = {
    enable = true;
    port = fleetSettings.sequoia.ports.glances;
  };

  services = {
    prometheus = {
      # Grabs metrics from this machine
      exporters.node.port = lib.mkForce fleetSettings.sequoia.ports.prometheus.exporter;
      # Main prometheus service
      enable = true;
      port = fleetSettings.sequoia.ports.prometheus.service;

      scrapeConfigs = [
        # Scrape local host
        {
          job_name = "sequoia";
          static_configs = [{ targets = [ "127.0.0.1:${toString fleetSettings.sequoia.ports.prometheus.exporter}" ]; }];
        }
        # Scrape docker container resource states
        {
          job_name = "sequoia-containers";
          static_configs = [{ targets = [ "127.0.0.1:8081" ]; }];
        }
        # Checks mc containers
        {
          job_name = "minecraft-lan-bridge";
          static_configs = [{
            targets = [
              fleetSettings.sequoia.containers.mc-ts.lan
              fleetSettings.sequoia.containers.mc-ts.lan
            ];
          }];
        }
        # Checks juniper
        {
          job_name = "juniper";
          static_configs = [{
            targets = [ (fleetSettings.juniper.lan + ":${toString fleetSettings.juniper.ports.prometheus}") ];
          }];
        }
      ];
    };

    cadvisor = {
      enable = true;
      port = 8081;
    };

    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = fleetSettings.sequoia.ports.grafana;
        };
        security.secret_key = config.sops.secrets.grafana_key.path;
      };

      # Makes dashboards
      provision = {
        enable = true;
        # Automatically connect Grafana to your local Prometheus instance
        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:${toString fleetSettings.sequoia.ports.prometheus.service}";
              isDefault = true;
            }
          ];
        };

        # Declaratively download and install dashboards
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "Node Exporter (Hosts)";
              options.path = pkgs.stdenv.mkDerivation {
                name = "node-exporter-dashboard";
                src = pkgs.fetchurl {
                  url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
                  sha256 = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM="; 
                };
                dontUnpack = true;
                installPhase = ''
                  mkdir -p $out
                  cp $src $out/node-exporter.json
                '';
              };
            }
            {
              name = "cAdvisor (Docker & Minecraft)";
              options.path = pkgs.stdenv.mkDerivation {
                name = "cadvisor-dashboard";
                src = pkgs.fetchurl {
                  url = "https://grafana.com/api/dashboards/14282/revisions/1/download";
                  sha256 = "sha256-dqhaC4r4rXHCJpASt5y3EZXW00g5fhkQM+MgNcgX1c0=";
                };
                dontUnpack = true;
                installPhase = ''
                  mkdir -p $out
                  cp $src $out/cadvisor.json
                '';
              };
              inputs = [
                {
                  name = "DS_PROMETHEUS";
                  type = "datasource";
                  pluginId = "prometheus";
                  value = "Prometheus"; # Matches the name in your datasources block
                }
              ];
            }
          ];
        };
      };
    };
  };

  # injects env file into grafana for secrets
  systemd.services = {
    grafana.serviceConfig.EnvironmentFile = config.sops.secrets.grafana_env.path;
    # Give cAdvisor access to the host's container runtimes and cgroups
    cadvisor.serviceConfig = {
      # Expose essential sockets and metrics
      BindReadOnlyPaths = [
        "/run/docker.sock"
        "/sys/fs/cgroup"
      ];
      
      # Ensure systemd allows mount namespacing to succeed even if paths are busy
      MountFlags = "shared";
    };
  };

  networking.firewall.allowedTCPPorts = with fleetSettings.sequoia.ports; [ glances grafana ];
}
