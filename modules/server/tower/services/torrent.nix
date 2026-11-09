{ config, pkgs, fleetSettings, lib, ... }: let
  user = "torrent";

  inherit (fleetSettings.sequoia.users.torrent) uid subStart subCount;
  uidStr = toString uid;

  qbitPort = toString fleetSettings.sequoia.ports.qbit;
  exitNode = fleetSettings.sequoia.containers.tail-torrent;

  dns = "194.242.2.2";

  # UID/GID qBittorrent runs as inside the container (PUID/PGID)
  puid = 1000;

  # Container UID N (N >= 1) -> host (subStart + N - 1).
  qbitHostIdInt = subStart + puid - 1;
  qbitHostId = toString qbitHostIdInt;

  podman = "${config.virtualisation.podman.package}/bin/podman";

  # Run podman as the rootless user from root-owned services
  asTorrent = "${pkgs.util-linux}/bin/runuser -u ${user} -- ${pkgs.coreutils}/bin/env XDG_RUNTIME_DIR=/run/user/${uidStr} ${podman}";

  # Installed inside the pod's network namespace (via podman exec).
  # qBittorrent's UID may only send via lo / tailscale0.
  # tailscaled runs as container root, so it is NOT matched and can still
  # reach the control plane / DERP over eth0.
  killswitchRules = pkgs.writeText "qbit-killswitch.sh" ''
    set -e
    for ipt in iptables-nft ip6tables-nft; do
      $ipt -N QBIT_KILLSWITCH 2>/dev/null || $ipt -F QBIT_KILLSWITCH
      $ipt -A QBIT_KILLSWITCH -o lo -j ACCEPT
      # WebUI replies to clients (LAN or tailnet via the host)
      $ipt -A QBIT_KILLSWITCH -p tcp --sport ${qbitPort} -j ACCEPT
      # never reach tailnet peers
      if [ "$ipt" = iptables-nft ]; then
        $ipt -A QBIT_KILLSWITCH -d 100.64.0.0/10 -j REJECT
      else
        $ipt -A QBIT_KILLSWITCH -d fd7a:115c:a1e0::/48 -j REJECT
      fi
      $ipt -A QBIT_KILLSWITCH -o tailscale0 -j ACCEPT
      $ipt -A QBIT_KILLSWITCH -j REJECT
      $ipt -C OUTPUT -m owner --uid-owner ${toString puid} -j QBIT_KILLSWITCH 2>/dev/null || \
        $ipt -I OUTPUT 1 -m owner --uid-owner ${toString puid} -j QBIT_KILLSWITCH
    done
  '';
in {
  imports = [
    (import ../../../../lib/mkPod.nix {
      name = user;
      inherit uid subStart subCount;
    })
  ];

  # Host-side group whose GID equals qBittorrent's in-container GID (as seen
  # from the host). Any host service that needs to touch downloads (Lidarr,
  # Sonarr, Radarr, ...) just adds "downloads" to its extraGroups.
  users.groups.downloads.gid = qbitHostIdInt;

  sops.secrets.tailscale_torrent_key = {
    sopsFile = ../../../../secrets/tower.yaml;
    owner = user; # the podman units run as this user
  };

  environment.persistence."/persist".directories = [
    "/var/lib/tailscale-torrent"
  ];

  systemd.tmpfiles.rules = [
    # tailscale: container root == host `torrent`
    "d /var/lib/tailscale-torrent 0700 ${user} ${user} -"
    "Z /var/lib/tailscale-torrent - ${user} ${user} -"

    # qbittorrent: container UID/GID 1000 == host subStart + 999
    "d /appdata/qbittorrent 0750 ${qbitHostId} ${qbitHostId} -"
    "Z /appdata/qbittorrent - ${qbitHostId} ${qbitHostId} -"

    # No recursive Z here (could be huge / slow); do a one-time chown -R of
    # existing data to ${qbitHostId} when changing subStart.
    # 2775: setgid so new subdirs keep the `downloads` group; group-writable
    # so the *arr apps can import (move) and clean up.
    "d /media/downloads 2775 ${qbitHostId} ${qbitHostId} -"
  ];

  boot.kernelModules = [ "xt_owner" "nf_tables" "nft_compat" "nft_reject_inet" ];

  networking.firewall.allowedTCPPorts = [ fleetSettings.sequoia.ports.qbit ];

  systemd.services = {
    # Creates the pod (owns the shared netns) and the auth key env file
    podman-tailscale-torrent = {
      serviceConfig = {
        RuntimeDirectory = "tailscale-torrent"; # /run/tailscale-torrent, owned by `torrent`
        RuntimeDirectoryMode = "0700";
      };
      preStart = lib.mkBefore ''
        umask 077
        printf 'TS_AUTHKEY=%s\n' "$(tr -d '\n' < ${config.sops.secrets.tailscale_torrent_key.path})" \
          > /run/tailscale-torrent/env

        ${podman} pod rm -f torrent >/dev/null 2>&1 || true
        ${podman} pod create --name torrent \
          --publish ${qbitPort}:${qbitPort} \
          --dns ${dns}
      '';
    };

    # qBittorrent never starts at boot on its own (autoStart = false below):
    # only after the kill switch is installed, and only when the watchdog says
    # we're exiting via Mullvad.
    podman-qbittorrent = {
      requires = [ "qbit-killswitch.service" ];
      after = [ "qbit-killswitch.service" ];
    };

    # Install firewall rules inside the pod's netns
    qbit-killswitch = {
      description = "Install qBittorrent kill switch in the tailscale netns";
      requires = [ "podman-tailscale-torrent.service" ];
      after = [ "podman-tailscale-torrent.service" ];
      partOf = [ "podman-tailscale-torrent.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.coreutils ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        for i in $(seq 1 30); do
          if ${asTorrent} exec -i tailscale-torrent sh -s < ${killswitchRules}; then
            exit 0
          fi
          sleep 1
        done
        exit 1
      '';
    };

    # Start qBittorrent only while exiting via Mullvad; stop it otherwise
    qbit-vpn-watchdog = {
      description = "Stop qBittorrent unless exiting via Mullvad";
      requires = [ "qbit-killswitch.service" ];
      after = [ "qbit-killswitch.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.systemd pkgs.gnugrep pkgs.coreutils ];
      serviceConfig = { Restart = "always"; RestartSec = 5; };
      script = ''
        set +e            # NixOS adds -e; every failure below is handled explicitly
        cd /              # the torrent user can't read the caller's cwd
    
        probeUrl="https://am.i.mullvad.net/json"
        interval=15
        stopAfter=4       # consecutive inconclusive probes before stopping qbit (~1 min)
        startAfter=2      # consecutive good probes before starting qbit
        healAfter=12      # consecutive broken-exec loops (~3 min) before restarting the tailscale container
        bad=0; good=0; execFail=0
    
        while true; do
    
          # 0. Can we exec into the tailscale container at all?
          #    If not, this is a host/podman problem, not a VPN verdict.
          if ! execOut=$(${asTorrent} exec tailscale-torrent true 2>&1); then
            execFail=$((execFail + 1)); good=0
            echo "podman exec failing ($execFail/$healAfter): $(echo "$execOut" | head -c 300)"
            systemctl stop podman-qbittorrent.service
            if [ "$execFail" -ge "$healAfter" ]; then
              echo "--- diagnostics before heal ---"
              ${asTorrent} ps -a --pod 2>&1 | head -20
              ${asTorrent} --log-level=debug exec tailscale-torrent true 2>&1 | tail -30
              journalctl -u podman-tailscale-torrent -n 30 --no-pager 2>&1
              echo "--- restarting tailscale container ---"
              systemctl restart --no-block podman-tailscale-torrent.service
              execFail=0
            fi
            sleep "$interval"; continue
          fi
          execFail=0
    
          # 1. Kill switch must exist in the *current* netns (pod recreation wipes it)
          if ! ${asTorrent} exec tailscale-torrent iptables-nft -C OUTPUT \
                -m owner --uid-owner ${toString puid} -j QBIT_KILLSWITCH >/dev/null 2>&1; then
            echo "kill switch missing: stopping qbittorrent, reinstalling"
            systemctl stop podman-qbittorrent.service
            out=$(${asTorrent} exec -i tailscale-torrent sh -s < ${killswitchRules} 2>&1) \
              || echo "reinstall failed: $(echo "$out" | head -c 300)"
            good=0; sleep 5; continue
          fi
    
          # 2. Are we exiting via Mullvad?
          out=$(${asTorrent} exec tailscale-torrent wget -qO- -T 10 "$probeUrl" 2>&1); rc=$?
          if echo "$out" | grep -Eq '"mullvad_exit_ip"[[:space:]]*:[[:space:]]*true'; then
            verdict=ok
          elif echo "$out" | grep -Eq '"mullvad_exit_ip"[[:space:]]*:[[:space:]]*false'; then
            verdict=notmullvad    # a real answer, and it says no
          else
            verdict=unknown       # timeout / DNS / TLS / bad response
          fi
    
          case "$verdict" in
            ok)
              bad=0; good=$((good + 1))
              if [ "$good" -ge "$startAfter" ] && ! systemctl is-active --quiet podman-qbittorrent.service; then
                echo "mullvad ok (x$good), starting qbittorrent"
                systemctl start podman-qbittorrent.service || echo "start failed"
              fi
              ;;
            notmullvad)
              good=0; bad=$stopAfter
              echo "NOT a mullvad exit: $(echo "$out" | head -c 300)"
              systemctl stop podman-qbittorrent.service
              ;;
            *)
              good=0; bad=$((bad + 1))
              echo "inconclusive (rc=$rc, $bad/$stopAfter): $(echo "$out" | head -c 200)"
              if [ "$bad" -ge "$stopAfter" ]; then
                systemctl stop podman-qbittorrent.service
              fi
              ;;
          esac
    
          sleep "$interval"
        done
      '';
    };
  };
  # Containers
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      tailscale-torrent = {
        podman.user = user;
        image = "docker.io/tailscale/tailscale:latest";
        environmentFiles = [ "/run/tailscale-torrent/env" ];
        environment = {
          TS_STATE_DIR = "/var/lib/tailscale-torrent";
          TS_EXTRA_ARGS = "--exit-node=${exitNode} --exit-node-allow-lan-access=true --shields-up";
          TS_USERSPACE = "false";
        };
        extraOptions = [
          "--pod=torrent" # publish + dns are set on the pod itself
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
        volumes = [
          "/var/lib/tailscale-torrent:/var/lib/tailscale-torrent"
        ];
      };

      qbittorrent = {
        podman.user = user;
        image = "lscr.io/linuxserver/qbittorrent:latest";
        autoStart = false; # started by qbit-vpn-watchdog
        dependsOn = [ "tailscale-torrent" ];
        environment = {
          PUID = toString puid;
          PGID = toString puid;
          TZ = "UTC";
          WEBUI_PORT = qbitPort;
          UMASK = "002"; # group-writable files/dirs for the *arr apps
        };
        extraOptions = [
          "--pod=torrent" # shares the tailscale container's netns
        ];
        volumes = [
          "/appdata/qbittorrent:/config"
          # Same path inside and out, so qBittorrent reports paths Lidarr/Sonarr/
          # Radarr can open directly (no Remote Path Mapping needed).
          "/media/downloads:/media/downloads"
        ];
      };
    };
  };
}
