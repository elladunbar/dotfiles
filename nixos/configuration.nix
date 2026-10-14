{ config, lib, pkgs, ... }:
let
  llama-cpp-service-package = config.services.llama-cpp.package;

  # game streaming (moonlight/sunshine) and ssh, open to the home lan only.
  # ports and port ranges ("47998:48000") both go here; the firewall below
  # turns them into one accept rule per protocol and source
  lanTCPPorts = [
    "17227" # sshd
    "47984" # sunshine
    "47989" # sunshine
    "48010" # sunshine
  ];
  lanUDPPorts = [
    "47998:48000" # moonlight
    "48002" # moonlight
    "48010" # moonlight
  ];

  # who counts as "the home lan" on eno1: the v4 subnet, v6 link-local (so
  # mDNS names like river-birch.local keep working), and the on-link v6
  # prefix. the tailnet needs none of this; tailscaled accepts tailscale0
  # ahead of the firewall, and everything else binds to loopback or to
  # 100.64.0.5 (tailnet) anyway
  lanSources = {
    iptables = [ "192.168.1.0/24" ];
    ip6tables = [
      "fe80::/10"
      "2600:1700:6900:baa0::/64" # the on-link v6 prefix; update if it gets renumbered
    ];
  };

  lanRules =
    family: proto: ports:
    lib.concatMapStrings (
      source:
      lib.concatMapStrings (port: ''
        ${family} -A nixos-fw -p ${proto} -s ${source} --dport ${port} -j nixos-fw-accept
      '') ports
    ) lanSources.${family};
in
{
  imports = [
    ./bluesky-pds.nix
    ./cachix.nix
    ./copyparty.nix
    ./forgejo.nix
    ./hardware-configuration.nix
    ./immich.nix
    ./llama-cpp.nix
    ./minecraft.nix
    ./nginx.nix
    ./sops.nix
    ./zfs.nix
  ];

  networking.hostId = "0d5482dd";
  networking.hostName = "river-birch";
  networking.useDHCP = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "caps:escape";

  environment.shells = with pkgs; [
    dash
  ];
  users.users.ella = {
    shell = pkgs.dash;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # dogwood (MacBook Pro)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYBHi8dV73Mf/QQ3jElrBaq0A1k935mSo6T4yyM1KL7 ella@dogwood.local"
      # ginkgo (Desktop)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8Rt9FfbktkJgZYJE7xMh7gXT3D0MfCEpVNMByC8dZl ella@ginkgo"
      # trillium (iPhone)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJfe2kyaRYcyo4CnzpJYiR/w6wXJV8QhHU5FqVAR1kxF edunbar02@gmail.com"
      # magnolia (XPS 13)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJc7mssoZiJ3laDCNTU6/C404j4g7nEjHDNbqrkazb7a ella@magnolia"
    ];
  };

  environment.systemPackages = with pkgs; [
    autoconf
    browsh
    cachix
    ccache
    clang-tools
    cmake
    dool
    foot
    gcc
    ghostty
    git
    gnumake
    iotop
    jq
    llama-cpp-service-package
    minhtml
    neovim
    ninja
    pandoc
    pkg-config
    plocate
    procps
    smartmontools
    sops
    sysstat
    util-linux
    wget
  ];
  # nixpkgs.overlays = [
  #   (self: super: {
  #     cudaPackages = super.cudaPackages_12;
  #   })
  # ];
  nixpkgs.overlays = [
    (self: super: {
      cudaPackages = super.cudaPackages_12.overrideScope (
        final: prev: {
          # cuDNN 9.12+ dropped kernels for compute capability < 7.5 and 9.11's
          # convolution kernels also fail on the GTX 1070 (sm_61); 9.10.2 works.
          cudnn = prev.cudnn.overrideAttrs (old: {
            passthru = old.passthru // {
              release = old.passthru.release // {
                version = "9.10.2.21";
                cuda_variant = [ "12" ];
                linux-x86_64.cuda12 = {
                  relative_path = "cudnn/linux-x86_64/cudnn-linux-x86_64-9.10.2.21_cuda12-archive.tar.xz";
                  sha256 = "d0defcbc4c6dad711ff4cb66d254036a300c9071b07c7b64199aacab534313c1";
                };
              };
            };
          });
        }
      );
    })
    (final: prev: {
      python3 = prev.python3.override {
        packageOverrides = pyFinal: pyPrev: {
          imageio = pyPrev.imageio.overridePythonAttrs (oldAttrs: {
            disabledTests = (oldAttrs.disabledTests or [ ]) ++ [
              "test_lagging_video_stream"
              "test_process_termination"
            ];
          });
        };
      };
    })
  ];

  services.tailscale.enable = true;

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh = {
    enable = true;
    # 17227 is opened for the home lan by networking.firewall.extraCommands;
    # openFirewall would re-open it on every interface, including public v6
    openFirewall = false;
    ports = [ 17227 ];
    settings = {
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = true;
    };
  };

  networking.firewall.extraCommands =
    # game streaming and ssh from the home lan only. the old blanket lists are
    # gone: 17228 is only the initrd dropbear (no firewall there), and nginx,
    # forgejo, pds, llama.cpp and minecraft all bind to loopback or to
    # 100.64.0.5, so they never need a hole for eno1
    lanRules "iptables" "tcp" lanTCPPorts
    + lanRules "iptables" "udp" lanUDPPorts
    + lanRules "ip6tables" "tcp" lanTCPPorts
    + lanRules "ip6tables" "udp" lanUDPPorts;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # 6 cores / 8 GB RAM: running fewer builds at once keeps large CUDA
    # compiles out of swap
    cores = 5;
    max-jobs = 2;
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = false;
    # cudaSupport is enabled per package (llama-cpp, onnxruntime) rather than
    # globally, so packages that don't use the GPU still come from the cache
    cudaCapabilities = [ "6.1" ];
  };

  boot.loader.grub = {
    enable = true;
    configurationLimit = 5;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        devices = [ "nodev" ];
        path = "/boot";
      }
    ];
  };

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.extraModprobeConfig = ''
    options nvidia_drm modeset=1 fbdev=1
  '';
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "e1000e"
  ];

  boot.kernelModules = [ "e1000e" ];
  boot.kernelParams = [
    "ip=192.168.1.100::::river-birch:eno1::::"
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percentage=20"
    "zswap.shrinker_enabled=1"
    # headless: reboot after a panic instead of sitting on the panic screen
    "panic=30"
  ];

  # headless: if a mount fails, keep booting so ssh comes up, rather than
  # stopping at an emergency shell that only a local console can reach
  systemd.enableEmergencyMode = false;
  # reset the machine via the iTCO hardware watchdog if the system hard-hangs
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  boot.initrd.network = {
    enable = true;
    udhcpc.enable = false;
    ssh = {
      enable = true;
      port = 17228;
      hostKeys = [ /etc/ssh/ssh_host_ed25519_key ];
      authorizedKeys = [
        # dogwood (MacBook Pro)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYBHi8dV73Mf/QQ3jElrBaq0A1k935mSo6T4yyM1KL7 dunb@dogwood.local"
        # ginkgo (Desktop)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8Rt9FfbktkJgZYJE7xMh7gXT3D0MfCEpVNMByC8dZl ella@ginkgo"
        # trillium (iPhone)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJfe2kyaRYcyo4CnzpJYiR/w6wXJV8QhHU5FqVAR1kxF edunbar02@gmail.com"
        # magnolia (XPS 13)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJc7mssoZiJ3laDCNTU6/C404j4g7nEjHDNbqrkazb7a ella@magnolia"
      ];
      extraConfig = "PermitRootLogin yes";
    };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
