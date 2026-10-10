{
  lib,
  config,
  pkgs,
  ...
}:
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

  # forgejo serves files in custom/public/assets/img over its embedded ones,
  # so swap every copy of the F logo for the little guy
  systemd.tmpfiles.rules =
    let
      logos =
        pkgs.runCommand "forgejo-logos"
          {
            nativeBuildInputs = [ pkgs.resvg ];
          }
          ''
            mkdir $out
            cp ${./forgejo/logo.svg} $out/logo.svg
            cp ${./forgejo/logo.svg} $out/favicon.svg
            resvg -w 512 $out/logo.svg $out/logo.png
            resvg -w 180 $out/logo.svg $out/favicon.png
            resvg -w 180 $out/logo.svg $out/apple-touch-icon.png
            resvg -w 200 $out/logo.svg $out/avatar_default.png
            # shown while migrating a repo; make him hop instead of drawing the F
            sed -e 's|viewBox="[^"]*"|viewBox="121 115 1800 1800"|' \
              -e 's|<g |<style>@keyframes hop{0%,to{transform:translateY(0)}50%{transform:translateY(-120px)}}g{animation:hop 1s ease-in-out infinite}</style>\n  <g |' \
              $out/logo.svg > $out/forgejo-loading.svg
          '';
    in
    [
      "d ${cfg.customDir}/public 0750 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.customDir}/public/assets 0750 ${cfg.user} ${cfg.group} - -"
      "L+ ${cfg.customDir}/public/assets/img - - - - ${logos}"
    ];

  sops.secrets.forgejo-admin-password.owner = "forgejo";
  systemd.services.forgejo.preStart =
    let
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
