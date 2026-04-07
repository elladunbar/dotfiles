{ config, ... }:
let
  forgejoSettings = config.services.forgejo.settings.server;
in
{
  # let nginx access anubis unix sockets
  users.groups.anubis.members = [ "nginx" ];

  services.anubis.instances.forgejo = {
    enable = true;
    settings = {
      COOKIE_DOMAIN = "elladunbar.com";
      TARGET = "${forgejoSettings.LOCAL_ROOT_URL}";
    };
  };
}
