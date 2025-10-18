{ config, pkgs, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf mkForce;
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

    logDir = mkOption {
      type = path;
      default = "${cfg.dataDir}/logs";
      defaultText = "\${cfg.dataDir}/logs";
      description = ''
        Directory to store Overleaf logs.
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

        "${cfg.logDir}"."d" = {
          mode = "700";
          inherit (cfg) user group;
        };
      };
    };

    users = {
      users = mkIf (cfg.user == "overleaf") {
        "overleaf" = {
          isSystemUser = true;
          inherit (cfg) group;
          shell = "/sbin/nologin";
        };
      };
      groups = mkIf (cfg.group == "overleaf") { "overleaf" = { }; };
    };

    virtualisation = {
      podman = {
        enable = true;
        autoPrune.enable = true;
      };
    };

    # Enable container name DNS for all Podman networks.
    networking.firewall = {
      allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
    };

    virtualisation.oci-containers.backend = mkForce "podman";

    # Networks
    systemd.services."overleaf-network" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f overleaf";
      };
      script = ''
        podman network inspect overleaf || podman network create overleaf
      '';
      partOf = [ "overleaf-root.target" ];
      wantedBy = [ "overleaf-root.target" ];
    };

    # Root service
    systemd.targets."overleaf-root" = {
      unitConfig = { Description = "Root Overleaf service."; };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
