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
}
