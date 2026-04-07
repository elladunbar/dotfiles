{ ... }:

{
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      flags = "-k -p -u";
    };
  };
}
