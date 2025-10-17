{ config, lib, ... }:
with lib;
let cfg = config.services.overleaf;
in {
  config = mkIf cfg.enable {
    environment.etc."overleaf/mongodb-init-replica-set.js" = {
      inherit (cfg) user group;
      text = ''
        /* eslint-disable no-undef */

        rs.initiate({ _id: 'overleaf', members: [{ _id: 0, host: 'mongo:27017' }] })
      '';
    };
    systemd = {
      tmpfiles.settings.overleafDirs = {
        "${cfg.dataDir}/mongo_data"."d" = {
          mode = "700";
          inherit (cfg) user group;
        };
      };
    };

    virtualisation.oci-containers.containers."mongo" = {
      user = "${cfg.user}:${cfg.group}";
      image = "mongo:6.0";
      environment = { "MONGO_INITDB_DATABASE" = "sharelatex"; };
      volumes = [
        "/etc/overleaf/mongodb-init-replica-set.js:/docker-entrypoint-initdb.d/mongodb-init-replica-set.js:rw"
        "${cfg.dataDir}/mongo_data:/data/db:rw"
      ];
      cmd = [ "--replSet" "overleaf" ];
      log-driver = "journald";
      extraOptions = [
        "--add-host=mongo:127.0.0.1"
        "--health-cmd=echo 'db.stats().ok' | mongosh localhost:27017/test --quiet"
        "--health-interval=10s"
        "--health-retries=5"
        "--health-timeout=10s"
        "--network-alias=mongo"
        "--network=overleaf_default"
      ];
    };
    systemd.services."podman-mongo" = {
      serviceConfig = { Restart = lib.mkOverride 90 "always"; };
      after = [ "podman-network-overleaf_default.service" ];
      requires = [ "podman-network-overleaf_default.service" ];
      partOf = [ "podman-compose-overleaf-root.target" ];
      wantedBy = [ "podman-compose-overleaf-root.target" ];
    };
  };
}
