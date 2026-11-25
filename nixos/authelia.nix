{ config, ... }:
let
  domain = "elladunbar.com";
  lldapSettings = config.services.lldap.settings;
  immichDomain = config.services.immich.settings.server.externalDomain;
  mealieDomain = config.services.mealie.settings.BASE_URL;
  smtp = config.programs.msmtp.accounts.default;
  secret = name: config.sops.secrets."authelia/${name}".path;

  # authelia reads the client secret digests from its credentials directory
  # through the config template filter (enabled by the module because
  # oidcIssuerPrivateKeyFile is set), so the digests stay out of the store
  credential = name: ''{{ mustEnv "CREDENTIALS_DIRECTORY" | printf "%s/${name}" | secret }}'';
in
{
  # every secret is root-owned and reaches authelia through LoadCredential
  sops.secrets = {
    "authelia/jwt-secret".sopsFile = ./secrets/sso.yaml;
    "authelia/storage-encryption-key".sopsFile = ./secrets/sso.yaml;
    "authelia/oidc-hmac-secret".sopsFile = ./secrets/sso.yaml;
    "authelia/oidc-issuer-private-key".sopsFile = ./secrets/sso.yaml;
    "authelia/immich-client-digest".sopsFile = ./secrets/sso.yaml;
    "authelia/mealie-client-digest".sopsFile = ./secrets/sso.yaml;
  };

  services.authelia.instances.main = {
    enable = true;

    secrets = {
      jwtSecretFile = secret "jwt-secret";
      storageEncryptionKeyFile = secret "storage-encryption-key";
      oidcHmacSecretFile = secret "oidc-hmac-secret";
      oidcIssuerPrivateKeyFile = secret "oidc-issuer-private-key";
    };

    # authelia binds to lldap as its admin, which also lets it reset passwords
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "%d/ldap-password";
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "%d/smtp-password";
    };

    settings = {
      theme = "auto";
      log = {
        level = "info";
        format = "text";
      };

      # only nginx reaches it; pine's caddy serves it as https://auth.elladunbar.com
      server.address = "tcp://127.0.0.1:9091/";

      authentication_backend.ldap = {
        address = "ldap://${lldapSettings.ldap_host}:${toString lldapSettings.ldap_port}";
        implementation = "lldap";
        base_dn = lldapSettings.ldap_base_dn;
        user = "uid=${lldapSettings.ldap_user_dn},ou=people,${lldapSettings.ldap_base_dn}";
      };

      # sign in with a passkey instead of a username; two_factor policies then
      # ask for the password as the second factor
      webauthn.enable_passkey_login = true;
      totp.issuer = domain;

      session.cookies = [
        {
          inherit domain;
          authelia_url = "https://auth.${domain}";
        }
      ];

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      # one-time codes (needed to register a passkey or totp) and password
      # reset links, through the migadu account in mail.nix
      notifier.smtp = {
        address = "submissions://${smtp.host}:${toString smtp.port}";
        username = smtp.user;
        sender = "Authelia <${smtp.from}>";
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "files.${domain}";
            policy = "two_factor";
          }
        ];
      };

      # immich creates an account for anyone it lets in (see immich.nix), so
      # only members of the lldap group photos are let through to it
      identity_providers.oidc.authorization_policies.photos = {
        default_policy = "deny";
        rules = [
          {
            policy = "two_factor";
            subject = "group:photos";
          }
        ];
      };

      identity_providers.oidc.clients = [
        {
          client_id = "immich";
          client_name = "Immich";
          client_secret = credential "immich-client-digest";
          public = false;
          authorization_policy = "photos";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [
            "${immichDomain}/auth/login"
            "${immichDomain}/user-settings"
            "app.immich:///oauth-callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
        {
          client_id = "mealie";
          client_name = "Mealie";
          client_secret = credential "mealie-client-digest";
          public = false;
          authorization_policy = "two_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "${mealieDomain}/login" ];
          # groups decides who is a mealie admin (see mealie.nix)
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];
    };
  };

  systemd.services.authelia-main = {
    # authelia checks the ldap connection at startup
    wants = [ "lldap.service" ];
    after = [ "lldap.service" ];
    serviceConfig.LoadCredential = [
      "ldap-password:${config.sops.secrets."lldap/admin-password".path}"
      "immich-client-digest:${secret "immich-client-digest"}"
      "mealie-client-digest:${secret "mealie-client-digest"}"
      "smtp-password:${config.sops.secrets.smtp-password.path}"
    ];
  };
}
