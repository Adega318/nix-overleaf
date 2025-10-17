{ config, lib, ... }:
let
  inherit (lib) mkOption mkIf mkOverride;
  inherit (lib.types) port;
  cfg = config.services.overleaf;
in {
  options.services.overleaf = {
    port = mkOption {
      type = port;
      description = "Port Number";
      default = 80;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."sharelatex" = {
      user = "${cfg.user}:${cfg.group}";
      image = "sharelatex/sharelatex";
      environment = {
        "DOCKER_RUNNER" = "true";
        "EMAIL_CONFIRMATION_DISABLED" = "true";
        "ENABLED_LINKED_FILE_TYPES" = "project_file,project_output_file";
        "ENABLE_CONVERSIONS" = "true";
        "OVERLEAF_APP_NAME" = "Overleaf Community Edition";
        "OVERLEAF_MONGO_URL" = "mongodb://mongo/sharelatex";
        "OVERLEAF_REDIS_HOST" = "redis";
        "REDIS_HOST" = "redis";
        "SANDBOXED_COMPILES" = "true";
        "SANDBOXED_COMPILES_HOST_DIR_COMPILES" =
          "/home/user/sharelatex_data/data/compiles";
        "SANDBOXED_COMPILES_HOST_DIR_OUTPUT" =
          "/home/user/sharelatex_data/data/output";
        "SANDBOXED_COMPILES_SIBLING_CONTAINERS" = "true";
      };
      volumes = [ "${cfg.projectsDir}:/var/lib/overleaf:rw" ];
      ports = [ "${toString cfg.port}:80/tcp" ];
      dependsOn = [ "mongo" "redis" ];
      log-driver = "journald";
      extraOptions =
        [ "--network-alias=sharelatex" "--network=overleaf_default" ];
    };
    systemd.services."podman-sharelatex" = {
      serviceConfig = {
        Restart = mkOverride 90 "always";
        User = cfg.user;
        Group = cfg.group;
      };
      after = [ "podman-network-overleaf_default.service" ];
      requires = [ "podman-network-overleaf_default.service" ];
      partOf = [ "podman-compose-overleaf-root.target" ];
      wantedBy = [ "podman-compose-overleaf-root.target" ];
    };
  };
}
