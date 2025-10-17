{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.services.overleaf;
in {
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
      user = "${cfg.user}:${cfg.group}";
      image = "redis:6.2";
      volumes = [ "${cfg.dataDir}/redis_data:/data:rw" ];
      log-driver = "journald";
      extraOptions = [ "--network-alias=redis" "--network=overleaf_default" ];
    };
    systemd.services."podman-redis" = {
      serviceConfig = { Restart = lib.mkOverride 90 "always"; };
      after = [ "podman-network-overleaf_default.service" ];
      requires = [ "podman-network-overleaf_default.service" ];
      partOf = [ "podman-compose-overleaf-root.target" ];
      wantedBy = [ "podman-compose-overleaf-root.target" ];
    };
  };
}
