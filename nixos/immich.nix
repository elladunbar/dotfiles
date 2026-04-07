{ ... }:

{
  users.users.immich.extraGroups = [ "render" "video" ];

  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;

    # enables access to all devices
    accelerationDevices = null;

    database = {
      enable = true;
      createDB = true;
    };

    settings.server = {
      externalDomain = "https://photos.elladunbar.com";
      loginPageMessage = "Welcome to Ella Dunbar's self-hosted photo storage!";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /var/cache/immich/matplotlib 0700 immich immich -"
    ];
    services = {
      immich-machine-learning = {
        environment = {
          MPLCONFIGDIR = "/var/cache/immich/matplotlib";
        };
      };
    };
  };
}
