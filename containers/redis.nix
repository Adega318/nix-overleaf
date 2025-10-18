{ config, lib, ... }:
let
  inherit (lib) mkOption mkIf mkOverride;
  inherit (lib.types) port str;
  cfg = config.services.overleaf;
in {
  options.services.overleaf.redis = {
    host = mkOption {
      type = str;
      description = "Redis database host.";
      default = "redis";
    };

    port = mkOption {
      type = port;
      description = "Redis port number.";
      default = 6379;
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      tmpfiles.settings.overleafDirs = {
        "${cfg.dataDir}/redis_data"."d" = {
          mode = "700";
          inherit (cfg) user group;
        };
      };
    };

    virtualisation.oci-containers.containers."redis" = {
      serviceName = "overleaf-redis";
      image = "redis:5.0";
      volumes = [ "${cfg.dataDir}/redis_data:/data:rw" ];
      cmd = [ "redis-server" "--appendonly" "yes" ];
      extraOptions =
        [ "--network-alias=redis" "--network=overleaf" "--expose=6379" ];
    };

    systemd.services."overleaf-redis" = {
      serviceConfig = { Restart = mkOverride 90 "always"; };
      after = [ "overleaf-network.service" ];
      requires = [ "overleaf-network.service" ];
      partOf = [ "overleaf-root.target" ];
      wantedBy = [ "overleaf-root.target" ];
    };
  };
}
