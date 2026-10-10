{ ... }:

{
  boot.zfs.forceImportRoot = false;
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      flags = "-k -p -u";
    };
  };

  # neither disk is redundant, so get early warning of failure
  services.smartd.enable = true;

  # Daily copy of the SSD pool onto the HDD, so losing the SSD costs at most a
  # day. Only the latest state is kept (--no-stream); point-in-time history is
  # in the auto-snapshots on `fast`. /nix isn't copied (rebuildable), and the
  # llama models are skipped via `syncoid:sync=false` on that dataset.
  services.syncoid = {
    enable = true;
    interval = "*-*-* 04:00:00";
    commonArgs = [ "--no-stream" ];
    # module default plus "destroy", so syncoid can prune its previous sync
    # snapshot on the backup side instead of leaving one behind every day
    localTargetAllow = [
      "change-key"
      "compression"
      "create"
      "mount"
      "mountpoint"
      "receive"
      "rollback"
      "destroy"
    ];
    commands = {
      "fast/system".target = "tank/backup/system";
      "fast/system".recursive = true;
      "fast/user".target = "tank/backup/user";
      "fast/user".recursive = true;
      "fast/data".target = "tank/backup/data";
      "fast/data".recursive = true;
    };
  };
}
