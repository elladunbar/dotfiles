{ config, ... }:

{
  # the user directory behind authelia (see authelia.nix). users and groups are
  # managed in its web ui, which nginx serves to the tailnet at
  # http://river-birch.nodes.elladunbar.com:17170; log in as "admin" with
  # /run/secrets/lldap/admin-password
  sops.secrets."lldap/admin-password".sopsFile = ./secrets/sso.yaml;

  services.lldap = {
    enable = true;
    settings = {
      # only authelia (and nginx, for the web ui) talk to it
      ldap_host = "127.0.0.1";
      http_host = "127.0.0.1";
      http_url = "http://river-birch.nodes.elladunbar.com:17170";
      ldap_base_dn = "dc=elladunbar,dc=com";
      # the admin password always comes from sops; changing it in the web ui
      # only lasts until the next restart
      force_ldap_user_pass_reset = "always";
    };
    # lldap runs as a DynamicUser, so hand it the root-owned secret as a
    # credential instead of chowning it
    environment.LLDAP_LDAP_USER_PASS_FILE = "%d/admin-password";
  };

  systemd.services.lldap.serviceConfig.LoadCredential = [
    "admin-password:${config.sops.secrets."lldap/admin-password".path}"
  ];
}
