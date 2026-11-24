{ config, ... }:
let
  smtp = config.programs.msmtp.accounts.default;
in
{
  # root-owned: systemd reads the env file below before dropping to mealie's
  # DynamicUser
  sops.secrets."mealie/oidc-client-secret".sopsFile = ./secrets/sso.yaml;
  sops.templates."mealie.env".content = ''
    OIDC_CLIENT_SECRET=${config.sops.placeholder."mealie/oidc-client-secret"}
    SMTP_PASSWORD=${config.sops.placeholder.smtp-password}
  '';

  services.mealie = {
    enable = true;
    # only nginx reaches it; pine's caddy serves it as https://recipes.elladunbar.com
    listenAddress = "127.0.0.1";
    port = 9000;
    # sqlite (the default), in /var/lib/private/mealie on fast/data, so it is
    # snapshotted and synced to tank with everything else
    credentialsFile = config.sops.templates."mealie.env".path;

    # the module passes these through toString, so booleans are written as
    # strings ("false" would otherwise become "", which mealie rejects)
    settings = {
      BASE_URL = "https://recipes.elladunbar.com";
      TZ = config.time.timeZone;

      # sso through authelia (see authelia.nix) is the only way in. mealie
      # creates a default admin with a published password on first start, so
      # password login stays off. any lldap user gets an account on first
      # login, and members of the lldap group admins are made admins, checked
      # again at every login
      ALLOW_SIGNUP = "false";
      ALLOW_PASSWORD_LOGIN = "false";
      OIDC_AUTH_ENABLED = "true";
      OIDC_SIGNUP_ENABLED = "true";
      OIDC_CONFIGURATION_URL = "https://auth.elladunbar.com/.well-known/openid-configuration";
      OIDC_CLIENT_ID = "mealie";
      OIDC_PROVIDER_NAME = "SSO";
      OIDC_ADMIN_GROUP = "admins";
      OIDC_AUTO_REDIRECT = "true";
      OIDC_REMEMBER_ME = "true";

      # invitation mail, through the migadu account in mail.nix
      SMTP_HOST = smtp.host;
      SMTP_PORT = smtp.port;
      SMTP_AUTH_STRATEGY = "SSL"; # implicit tls
      SMTP_FROM_NAME = "Mealie";
      SMTP_FROM_EMAIL = smtp.from;
      SMTP_USER = smtp.user;
    };
  };
}
