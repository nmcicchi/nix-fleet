# Uhh still under construction
{ config, pkgs, fleetSettings, lib, ... }: let
  user = "torrent";
  uid = 1001;
  uidStr = toString uid;

  qbitPort = toString fleetSettings.sequoia.ports.qbit;
  exitNode = fleetSettings.sequoia.containers.tail-torrent;

  dns = "194.242.2.2";

  # UID/GID qBittorrent runs as *inside* the container (PUID/PGID)
  puid = 1000;

  # Subordinate ID range for rootless podman.
  # Container UID 0 -> host `torrent` user.
  # Container UID N (N >= 1) -> host (subStart + N - 1).
  subStart = 100000;
  subCount = 65536;
  qbitHostId = toString (subStart + puid - 1); # container 1000 -> host 100999

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
  # User + secrets + persistence
  users.groups.${user} = { };
  users.users.${user} = {
    isNormalUser = true;
    inherit uid;
    group = user;
    linger = true; # keep /run/user/<uid> alive without a login session
    subUidRanges = [{ startUid = subStart; count = subCount; }];
    subGidRanges = [{ startGid = subStart; count = subCount; }];
  };

  sops.secrets.tailscale_torrent_key = {
    sopsFile = ../../../../secrets/tower.yaml;
    owner = user; # the podman units now run as this user
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/tailscale-torrent"
      # rootless podman image/container storage lives here
      { directory = "/home/${user}"; user = user; group = user; mode = "0700"; }
    ];
  };

  # Directories (managed by tmpfiles)
  #   d = create if missing, Z = recursively (re)apply ownership
  systemd.tmpfiles.rules = [
    # tailscale: container root == host `torrent`
    "d /var/lib/tailscale-torrent 0700 ${user} ${user} -"
    "Z /var/lib/tailscale-torrent - ${user} ${user} -"

    # qbittorrent: container UID/GID 1000 == host 100999
    "d /appdata/qbittorrent 0750 ${qbitHostId} ${qbitHostId} -"
    "Z /appdata/qbittorrent - ${qbitHostId} ${qbitHostId} -"

    # No recursive Z here (could be huge / slow); do a one-time chown for
    # existing data, see migration notes.
    "d /media/downloads 0775 ${qbitHostId} ${qbitHostId} -"
  ];

  # Podman (rootless)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  boot.kernelModules = [ "xt_owner" "nf_tables" "nft_compat" "nft_reject_inet" ];

  networking.firewall.allowedTCPPorts = [ fleetSettings.sequoia.ports.qbit ];

  systemd.services = {
    # Creates the pod (owns the shared netns) and the auth key env file
    podman-tailscale-torrent = {
      requires = [ "user-runtime-dir@${uidStr}.service" ];
      after = [ "user-runtime-dir@${uidStr}.service" ];
      environment.XDG_RUNTIME_DIR = "/run/user/${uidStr}";
      path = [ "/run/wrappers" ]; # newuidmap / newgidmap
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

    # qBittorrent never starts at boot on its own: only after the kill switch
    # is installed, and only when the watchdog says we're exiting via Mullvad.
    podman-qbittorrent = {
      requires = [ "user-runtime-dir@${uidStr}.service" "qbit-killswitch.service" ];
      after = [ "user-runtime-dir@${uidStr}.service" "qbit-killswitch.service" ];
      environment.XDG_RUNTIME_DIR = "/run/user/${uidStr}";
      path = [ "/run/wrappers" ];
      wantedBy = lib.mkForce [ ];
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
        fails=0
        while true; do
          if ${asTorrent} exec tailscale-torrent wget -qO- -T 10 https://am.i.mullvad.net/json 2>/dev/null \
              | grep -Eq '"mullvad_exit_ip"[[:space:]]*:[[:space:]]*true'; then
            fails=0
            systemctl is-active --quiet podman-qbittorrent.service \
              || systemctl start podman-qbittorrent.service
          else
            fails=$((fails + 1))
            if [ "$fails" -ge 2 ]; then
              systemctl stop podman-qbittorrent.service
            fi
          fi
          sleep 15
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
        dependsOn = [ "tailscale-torrent" ];
        environment = {
          PUID = toString puid;
          PGID = toString puid;
          TZ = "UTC";
          WEBUI_PORT = qbitPort;
        };
        extraOptions = [
          "--pod=torrent" # shares the tailscale container's netns
        ];
        volumes = [
          "/appdata/qbittorrent:/config"
          "/media/downloads:/downloads"
        ];
      };
    };
  };
}
