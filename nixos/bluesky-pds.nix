{ config, ... }:

{
  sops.secrets."bluesky-pds/env".owner = "pds";

  services.bluesky-pds = {
    enable = true;
    pdsadmin.enable = true;
    environmentFiles = [ config.sops.secrets."bluesky-pds/env".path ];
    settings = {
      PDS_HOSTNAME = "pds.elladunbar.com";
      PDS_PORT = 3010;
      # PDS_EMAIL_SMTP_URL (smtps://, with the migadu password from mail.nix
      # embedded) is in the env secret
      PDS_EMAIL_FROM_ADDRESS = config.programs.msmtp.accounts.default.from;
    };
  };
}
