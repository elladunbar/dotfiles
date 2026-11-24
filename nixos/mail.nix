{ config, lib, ... }:
let
  smtp = config.programs.msmtp.accounts.default;
  alertsTo = "homelab@elladunbar.com";
  sendmail = "${config.security.wrapperDir}/sendmail";

  # same escaping the syncoid module uses for its unit names
  syncoidUnit =
    name:
    "syncoid-"
    + lib.concatMapStrings (s: if lib.isList s then "-" else s) (
      builtins.split "[^a-zA-Z0-9_.\\-]+" name
    );
in
{
  # the password of the noreply@elladunbar.com mailbox on migadu. root-only:
  # the web services get it through LoadCredential, and everything that uses
  # sendmail (smartd, zed, notify-failure@) runs as root
  sops.secrets.smtp-password = { };

  # a sendmail that relays through migadu, for the alerts below. the web
  # services speak smtp themselves and read their settings from this account
  # (see authelia.nix, forgejo.nix, immich.nix, bluesky-pds.nix)
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    accounts.default = {
      host = "smtp.migadu.com";
      port = 465; # implicit tls
      tls = true;
      tls_starttls = false;
      auth = true;
      user = "noreply@elladunbar.com";
      from = "noreply@elladunbar.com";
      passwordeval = "cat ${config.sops.secrets.smtp-password.path}";
      syslog = true; # each delivery (or failure) shows up in the journal
    };
  };

  # migadu only relays mail from the mailbox's own address, so smartd can't
  # use its default sender of root
  services.smartd.notifications.mail = {
    enable = true;
    sender = smtp.from;
    recipient = alertsTo;
  };

  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ alertsTo ];
    # also mail when a scrub finishes cleanly, so silence means zed is broken
    ZED_NOTIFY_VERBOSE = true;
  };

  # mails the status and journal of a failed unit; add
  # onFailure = [ "notify-failure@%n.service" ] to any unit to use it
  systemd.services = {
    "notify-failure@" = {
      description = "Email the journal of failed unit %i";
      serviceConfig.Type = "oneshot";
      scriptArgs = "%i";
      script = ''
        unit="$1"
        {
          echo "To: ${alertsTo}"
          echo "Subject: [${config.networking.hostName}] $unit failed"
          echo
          systemctl status --full --no-pager "$unit" || true
          echo
          journalctl --unit "$unit" --lines 200 --no-pager --output short-iso
        } | ${sendmail} -t
      '';
    };

    nixos-upgrade.onFailure = [ "notify-failure@%n.service" ];
  }
  // lib.mapAttrs' (
    name: _: lib.nameValuePair (syncoidUnit name) { onFailure = [ "notify-failure@%n.service" ]; }
  ) config.services.syncoid.commands;
}
