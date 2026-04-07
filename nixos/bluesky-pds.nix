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
      PDS_EMAIL_FROM_ADDRESS = "edunbar02@gmail.com";
    };
  };
}
