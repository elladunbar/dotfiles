{ lib, config, pkgs, ... }:
let
  cfg = config.services.forgejo;
  srv = cfg.settings.server;
in
{
  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    lfs.enable = true;
    settings = {
      DEFAULT = {
        APP_NAME = "Ellaforge";
      };
      server = {
        DOMAIN = "git.elladunbar.com";
        ROOT_URL = "https://${srv.DOMAIN}/";
        HTTP_PORT = 3000;
        LOCAL_ROOT_URL = "http://localhost:3000/";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "river-birch";
      url = srv.LOCAL_ROOT_URL;
      tokenFile = config.sops.secrets.forgejo-runner-token.path;
      labels = [
        "native:host"
      ];
    };
  };

  # forgejo is Type=notify, so this waits until it is actually accepting
  # connections instead of crash-looping the runner during startup
  systemd.services.gitea-runner-default = {
    wants = [ "forgejo.service" ];
    after = [ "forgejo.service" ];
  };

  sops.secrets.forgejo-admin-password.owner = "forgejo";
  systemd.services.forgejo.preStart = let
    adminCmd = "${lib.getExe cfg.package} admin user";
    pwd = config.sops.secrets.forgejo-admin-password;
    user = "super";
  in
  # sh
  ''
    ${adminCmd} create \
    --admin \
    --email "root@localhost" \
    --username ${user} \
    --password "$(tr -d '\n' < ${pwd.path})" \
    || true
  '';
}
