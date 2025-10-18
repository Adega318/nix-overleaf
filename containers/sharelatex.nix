{ config, lib, ... }:
let
  inherit (lib) mkOption mkIf mkOverride;
  inherit (lib.types) port str;
  cfg = config.services.overleaf;

  containerDataPath = "/var/lib/overleaf";
  containerLogPath = "/var/log/overleaf";
in {
  options.services.overleaf = {
    port = mkOption {
      type = port;
      description = "Port Number";
      default = 80;
    };

    host = mkOption {
      type = str;
      description = "External host for Overleaf.";
      default = "127.0.0.1";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."sharelatex" = {
      serviceName = "overleaf-sharelatex";
      image = "sharelatex/sharelatex";

      environment = {
        # variabes.env configurations.
        OVERLEAF_APP_NAME = "Our Overleaf Instance";
        ENABLED_LINKED_FILE_TYPES = "project_file,project_output_file";
        ENABLE_CONVERSIONS = "true";
        EMAIL_CONFIRMATION_DISABLED = "true";
        EXTERNAL_AUTH = "none";

        # baseline configs and overleaf.rc configs.
        GIT_BRIDGE_ENABLED = "false";
        GIT_BRIDGE_HOST = "git-bridge";
        GIT_BRIDGE_PORT = "8000";
        REDIS_HOST = cfg.redis.host;
        REDIS_PORT = toString cfg.redis.port;
        V1_HISTORY_URL = "http://sharelatex:3100/api";

        # extas
        OVERLEAF_IN_CONTAINER_DATA_PATH = containerDataPath;
        OVERLEAF_IN_CONTAINER_LOG_PATH = containerLogPath;
        OVERLEAF_MONGO_URL = cfg.mongo.url;
        OVERLEAF_REDIS_HOST = cfg.redis.host;
      };

      volumes = [
        "${cfg.projectsDir}:${containerDataPath}:rw"
        "${cfg.logDir}:${containerLogPath}:rw"
      ];
      ports = [ "${cfg.host}:${toString cfg.port}:80" ];
      dependsOn = [ "mongo" "redis" ];
      extraOptions = [ "--network-alias=sharelatex" "--network=overleaf" ];
    };

    systemd.services."overleaf-sharelatex" = {
      serviceConfig = { Restart = mkOverride 90 "always"; };
      after = [ "overleaf-network.service" ];
      requires = [ "overleaf-network.service" ];
      partOf = [ "overleaf-root.target" ];
      wantedBy = [ "overleaf-root.target" ];
    };
  };
}
