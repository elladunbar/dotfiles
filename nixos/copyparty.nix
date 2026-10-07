{ config, ... }:

{
  # fast/data/copyparty is mounted on /var/lib/copyparty (see
  # hardware-configuration.nix), so both the files and copyparty's state
  # (shares db, salts) are in the nightly syncoid backup
  services.copyparty = {
    enable = true;

    settings = {
      # only reachable through nginx
      i = "127.0.0.1";
      p = 3923;
      no-reload = true;
      hist = "/var/cache/copyparty";

      site = "https://files.elladunbar.com/";
      no-robots = true;

      # nginx (127.0.0.1, trusted by the default xff-src) sends exactly one
      # X-Forwarded-For entry holding the real client ip, so login bans hit
      # the client rather than pine
      rproxy = -1;

      usernames = true;
      # the salt isn't secret; it's pinned here so password hashes can be
      # generated before the first deploy
      ah-alg = "argon2";
      ah-salt = "S3aC5yaBqJHgwtJCkFhfpphd";

      # index and hash files, for search and resumable/deduplicated uploads
      e2dsa = true;
    };

    accounts.ella.passwordFile = config.sops.secrets.copyparty-ella-password.path;

    volumes."/" = {
      path = "/var/lib/copyparty/data";
      access.A = "ella";
    };
  };

  sops.secrets.copyparty-ella-password.owner = "copyparty";
}
