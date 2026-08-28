{ ... }:
let
  mcDir = "/var/lib/minecraft/raspberry";
in
{
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  systemd.services.docker-raspberry = {
    after = [ "network.target" "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
  };

  # ensure the data directory exists with correct ownership.
  systemd.tmpfiles.rules = [
    "d ${mcDir} 0750 911 911 -"
  ];

  virtualisation.oci-containers.containers.raspberry = {
    autoStart = true;
    image = "itzg/minecraft-server:java17";

    environment = {
      EULA = "TRUE";
      TYPE = "FORGE";
      VERSION = "1.19.2";
      PACKWIZ_URL = "https://asphodel.cc/packwiz/Ports/Curse/Raspberry-Server/pack.toml";
      MEMORY = "5000M";
      USE_AIKAR_FLAGS = "true";
      ENABLE_WHITELIST = "TRUE";
      ICON = "https://d1nhio0ox7pgb.cloudfront.net/_img/g_collection_png/standard/64x64/dog.png";
      MOTD = "dogcraft :3";
    };

    volumes = [
      "${mcDir}:/data"
    ];

    ports = [
      "100.64.0.5:25565:25565"
    ];

    extraOptions = [
      "--pull=always"
    ];
  };
}
