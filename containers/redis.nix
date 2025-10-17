{ lib, ... }: {
  virtualisation.oci-containers.containers."redis" = {
    image = "redis:6.2";
    volumes = [ "/home/adega/redis_data:/data:rw" ];
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
}
