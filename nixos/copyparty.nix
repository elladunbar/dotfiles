{
  config,
  lib,
  pkgs,
  ...
}:

{
  # fast/data/copyparty is mounted on /var/lib/copyparty (see
  # hardware-configuration.nix), so both the files and copyparty's state
  # (shares db, salts) are in the nightly syncoid backup
  services.copyparty = {
    enable = true;
    # the default ffmpeg-headless is built without libjxl, so video
    # thumbnails fail for browsers that accept jpeg-xl
    package = pkgs.copyparty.override { ffmpeg = pkgs.ffmpeg-full; };

    settings = {
      # only reachable through nginx, over a socket only the copyparty group
      # (nginx) can open. it trusts nginx's remote-user header (below), so a
      # tcp port on loopback would let any local process, like a forgejo
      # runner job, claim to be ella. socket clients count as 127.8.3.7,
      # which is inside the default xff-src
      i = "unix:770:copyparty:/run/copyparty/party.sock";
      no-reload = true;
      hist = "/var/cache/copyparty";

      site = "https://files.elladunbar.com/";
      no-robots = true;

      # nginx (127.0.0.1, trusted by the default xff-src) sends exactly one
      # X-Forwarded-For entry holding the real client ip, so login bans hit
      # the client rather than pine
      rproxy = -1;

      # files.elladunbar.com is behind authelia (members of the lldap group
      # files only), and nginx passes the signed-in user and their lldap
      # groups here; "ella" from lldap gets the "ella" account's access.
      # dav.elladunbar.com strips both headers, so webdav clients (rclone on
      # dogwood) log in with the copyparty password as before
      idp-h-usr = "remote-user";
      idp-h-grp = "remote-groups";
      idp-logout = "https://auth.elladunbar.com/logout";

      usernames = true;
      # the salt isn't secret; it's pinned here so password hashes can be
      # generated before the first deploy
      ah-alg = "argon2";
      ah-salt = "S3aC5yaBqJHgwtJCkFhfpphd";

      # index and hash files, for search and resumable/deduplicated uploads
      e2dsa = true;

      # let webdav clients (finder) overwrite existing files instead of
      # saving timestamped copies; also lets PUT uploads overwrite for
      # accounts with delete access, which is only ella
      daw = true;
    };

    accounts.ella.passwordFile = config.sops.secrets.copyparty-ella-password.path;

    # nested volumes replace the access of the volume they sit in, so ella
    # can't see into anyone else's folder. \${u} is copyparty's, not nix's:
    # one private folder per user at the top, created when copyparty first
    # sees them. usernames and top-level folders share one namespace, so a
    # user named after a folder in / (like "shared") would be given it
    volumes = {
      "/" = {
        path = "/var/lib/copyparty/data";
        access.A = "ella";
      };
      "/shared" = {
        path = "/var/lib/copyparty/data/shared";
        access = {
          A = "ella";
          rw = "@files";
        };
      };
      "/\${u}" = {
        path = "/var/lib/copyparty/data/\${u}";
        access.A = "\${u}";
      };
    };
  };

  sops.secrets.copyparty-ella-password.owner = "copyparty";

  # nginx has to get into /run/copyparty (0700 by default) to reach the
  # socket. 0710 lets the group through without listing it, and the config
  # copy in there is 0600
  systemd.services.copyparty.serviceConfig.RuntimeDirectoryMode = lib.mkForce "0710";
  # a unit change restarts nginx, so the group takes effect; extraGroups on
  # the user would only reload it, leaving the running master without it
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "copyparty" ];
}
