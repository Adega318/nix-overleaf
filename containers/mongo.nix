{ config, lib, ... }:
let
  inherit (lib) mkOption mkIf mkOverride;
  inherit (lib.types) str;
  cfg = config.services.overleaf;
in {
  options.services.overleaf.mongo = {
    url = mkOption {
      type = str;
      description = "External url for MongoDB";
      default = "mongodb://mongo/sharelatex";
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      tmpfiles.settings.overleafDirs = {
        "${cfg.dataDir}/mongo_data"."d" = {
          mode = "700";
          inherit (cfg) user group;
        };
      };
    };

    virtualisation.oci-containers.containers."mongo" = {
      serviceName = "overleaf-mongo";
      image = "mongo:6.0";

      environment = { MONGO_INITDB_DATABASE = "sharelatex"; };

      volumes = [ "${cfg.dataDir}/mongo_data:/data/db:rw" ];
      cmd = [ "--replSet" "overleaf" ];
      extraOptions = [
        "--health-cmd=echo 'db.stats().ok' | mongosh localhost:27017/test --quiet"
        "--health-interval=10s"
        "--health-retries=5"
        "--health-timeout=10s"

        "--network-alias=mongo"
        "--network=overleaf"
        "--expose=27017"
      ];
    };

    systemd.services."overleaf-mongo" = {
      serviceConfig = { Restart = mkOverride 90 "always"; };
      after = [ "overleaf-network.service" ];
      requires = [ "overleaf-network.service" ];
      partOf = [ "overleaf-root.target" ];
      wantedBy = [ "overleaf-root.target" ];
    };
  };
}
