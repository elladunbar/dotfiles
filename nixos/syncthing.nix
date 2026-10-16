{ config, ... }:

{
  # fast/data/syncthing is mounted on /var/lib/syncthing (see
  # hardware-configuration.nix), so the synced folders, keys and index db are
  # all auto-snapshotted and in the nightly syncoid backup; the snapshots
  # stand in for syncthing's own file versioning
  services.syncthing = {
    enable = true;

    # the gui stays on loopback; nginx serves it to the tailnet at
    # http://river-birch.nodes.elladunbar.com:8384
    guiAddress = "127.0.0.1:8384";

    # devices and folders are added through the gui, so don't wipe them on
    # every restart
    overrideDevices = false;
    overrideFolders = false;

    settings.options = {
      # sync only over the tailnet. tailscaled accepts tailscale0 ahead of the
      # firewall, so no hole is needed; other devices add river-birch with the
      # address tcp://100.64.0.5:22000
      listenAddresses = [
        "tcp://100.64.0.5:22000"
        "quic://100.64.0.5:22000"
      ];
      globalAnnounceEnabled = false;
      localAnnounceEnabled = false;
      relaysEnabled = false;
      natEnabled = false;

      urAccepted = -1;
    };

    # where the gui puts newly added or accepted folders. it starts out empty,
    # which makes folder paths relative to the service's working directory, /
    settings.defaults.folder.path = config.services.syncthing.dataDir;
  };
}
