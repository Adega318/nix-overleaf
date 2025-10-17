{ config, pkgs, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf;
  inherit (lib.types) str path bool;
  cfg = config.services.overleaf;
in {
  imports = [
    ./containers/sharelatex.nix
    ./containers/mongo.nix
    ./containers/redis.nix
  ];

  options.services.overleaf = {
    enable = mkEnableOption "Overleaf comunity edition service";

    user = mkOption {
      type = str;
      default = "overleaf";
      description = "User account under which Overleaf runs.";
    };

    group = mkOption {
      type = str;
      default = "overleaf";
      description = "Group under which Overleaf runs.";
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/overleaf";
      description = ''
        Base data directory.
      '';
    };

    projectsDir = mkOption {
      type = path;
      default = "${cfg.dataDir}/projects";
      defaultText = "\${cfg.dataDir}/projects";
      description = ''
        Directory to store Overleaf projects.
      '';
    };

    openFirewall = mkOption {
      type = bool;
      default = false;
      description = ''
        Open the default ports in the firewall for the media server.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      tmpfiles.settings.overleafDirs = {
        "${cfg.dataDir}"."d" = {
          mode = "700";
          inherit (cfg) user group;
        };

        "${cfg.projectsDir}"."d" = {
          mode = "700";
          inherit (cfg) user group;
        };
      };
    };

    users = {
      users.${cfg.user} = lib.mkDefault { isSystemUser = true; };
      groups.${cfg.group} = { members = [ cfg.user ]; };
    };

    virtualisation = {
      podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = true;
      };
    };

    # Enable container name DNS for all Podman networks.
    networking.firewall = {
      allowedTCPPorts = lib.mkIf cfg.openFirewall [ 80 ];
    };

    virtualisation.oci-containers.backend = "podman";

    # Networks
    systemd.services."podman-network-overleaf_default" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f overleaf_default";
      };
      script = ''
        podman network inspect overleaf_default || podman network create overleaf_default
      '';
      partOf = [ "podman-compose-overleaf-root.target" ];
      wantedBy = [ "podman-compose-overleaf-root.target" ];
    };

    # Root service
    systemd.targets."podman-compose-overleaf-root" = {
      unitConfig = { Description = "Root Overleaf service."; };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
