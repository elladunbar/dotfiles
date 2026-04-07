{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./bluesky-pds.nix
      ./cachix.nix
      ./forgejo.nix
      ./hardware-configuration.nix
      ./immich.nix
      ./llama-cpp.nix
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
    helix
    iotop
    jq
    lmstudio
    minhtml
    neovim
    ninja
    pandoc
    pkg-config
    plocate
    procps
    sops
    sysstat
    util-linux
    wget

    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvcc
    cudaPackages.cudatoolkit
    cudaPackages.cudnn

    linuxPackages.nvidia_x11

    stdenv.cc
  ];
  environment.sessionVariables = {
    CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
    CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      "${pkgs.cudaPackages.cudatoolkit}"
      "${pkgs.cudaPackages.cudatoolkit}/lib64"
      pkgs.cudaPackages.cudnn
      pkgs.cudaPackages.cuda_cudart
      pkgs.stdenv.cc.cc.lib
    ];
    CUDA_MODULE_LOADING = "LAZY";
  };

  services.tailscale.enable = true;

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    ports = [ 17227 ];
    settings = {
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 17228 17080 17443 18080 18443 19080 19443 47984 47989 48010 ];
  networking.firewall.allowedUDPPorts = [ 17228 17080 17443 18080 18443 19080 19443 48002 48010 ];
  networking.firewall.allowedUDPPortRanges = [ { from = 47998; to = 48000; } ];

  nix.settings = {
    # cores = 1;
    # max-jobs = 1;
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  boot.loader.grub = {
    enable = true;
    configurationLimit = 5;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.extraModprobeConfig = ''
    options nvidia_drm modeset=1 fbdev=1
  '';
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "e1000e" ];

  boot.kernelModules = [ "e1000e" ];
  boot.kernelParams = [
    "ip=192.168.1.100::::river-birch:eno1::::"
    # "zswap.enabled=1"
    # "zswap.compressor=zstd"
    # "zswap.max_pool_percentage=20"
    # "zswap.shrinker_enabled=1"
  ];
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

  swapDevices = lib.mkForce [];

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

