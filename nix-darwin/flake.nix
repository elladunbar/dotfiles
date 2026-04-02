{
  description = "MacOS configuration for dogwood";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, ... }:
  let
    configuration = { pkgs, ... }: {
      # Put config in home folder
      environment.etc.nix-darwin.source = "/Users/ella/.config/nix-darwin";

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
        bash
        bat
        btop
        ccache
        chafa
        cmake
        colima
        dash
        docker
        dos2unix
        eza
        fastfetch
        fd
        ffmpeg
        fish
        fzf
        git
        git-filter-repo
        git-lfs
        git-xet
        glow
        gnused
        go
        hexyl
        imagemagick
        julia-bin
        lynx
        magic-wormhole
        man
        mas
        minhtml
        mosh
        neovim
        nmap
        nodejs_25
        openssl
        pandoc
        perl
        php
        poppler
        ripgrep
        rsync
        rustup
        socat
        sqlcmd
        starship
        stow
        tailscale
        tealdeer
        texinfo
        tmux
        typst
        uv
        wget
        yazi
        yt-dlp
        zellij
        zstd

        lua51Packages.lua
        lua51Packages.luarocks

        (pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            ggthemes
            gt
            gtExtras
            languageserver
            tidyverse
            webshot2
          ];
        })
      ];

      # Homebrew
      homebrew = {
        enable = true;
        prefix = "/opt/homebrew";
        onActivation.autoUpdate = true;
        onActivation.cleanup = "uninstall";
        onActivation.upgrade = true;
        brews = [
          "ghcup"
          "mpv"
          "pi-coding-agent"
          "tree-sitter-cli"
        ];
        casks = [
          "anki"
          "box-drive"
          "calibre"
          "discord"
          "element"
          "firefox"
          "ghostty"
          "gimp"
          "google-chrome"
          "hammerspoon"
          "handy"
          "lm-studio"
          "localsend"
          "mactex"
          "moonlight"
          "netnewswire"
          "obs"
          "onlyoffice"
          "orion"
          "prism"
          "raycast"
          "readest"
          "sioyek"
          "spotify"
          "steam"
          "whatsapp"
          "zed"
          "zoom"
          "zotero"
        ];
        masApps = {
          Bitwarden = 1352778147;
          "Consent-O-Matic" = 1606897889;
        };
      };

      # Launch services
      launchd.agents = { # supposed to run as current user
        "appearance" = {
          environment = { "HOME" = "/Users/ella"; };
          serviceConfig = {
            Program = /Users/ella/Code/sh/appearance/appearance.sh;
            StandardErrorPath = "/Users/ella/Library/Caches/org.nixos.appearance/appearance_error.log";
            StandardOutPath = "/Users/ella/Library/Caches/org.nixos.appearance/appearance.log";
            StartInterval = 5;
            UserName = "ella";
          };
        };
      };
      launchd.daemons = { # run as specified user
        "llama-cpp" = {
          serviceConfig = {
            ProgramArguments = [
                "/Users/ella/.local/bin/llama-server"
                "--models-preset" "/Users/ella/.local/share/models/config.ini"
                "--models-max" "1"
                "--host" "dogwood.nodes.elladunbar.com"
                "--port" "5678"
                "--n-gpu-layers" "all"
                "--flash-attn" "on"
                "--no-mmap"
                "--parallel" "1"
                "--kv-unified"
                "--cache-type-k" "q8_0"
                "--cache-type-v" "q8_0"
                "--batch-size" "2048"
                "--ubatch-size" "2048"
                "--jinja"
            ];
            KeepAlive = true;
            StandardErrorPath = "/Users/ella/Library/Caches/org.nixos.llama-cpp/llama-cpp_error.log";
            StandardOutPath = "/Users/ella/Library/Caches/org.nixos.llama-cpp/llama-cpp.log";
            UserName = "ella";
          };
        };
        "tailscaled" = {
          command = "tailscaled";
          path = [
            "/run/current-system/sw/bin"
            "/sbin"
          ];
          serviceConfig = {
            KeepAlive = true;
            StandardErrorPath = "/Users/ella/Library/Caches/org.nixos.tailscaled/tailscaled_error.log";
            StandardOutPath = "/Users/ella/Library/Caches/org.nixos.tailscaled/tailscaled.log";
            UserName = "root";
          };
        };
      };

      # System settings
      security.pam.services.sudo_local.touchIdAuth = true;
      system.defaults.CustomUserPreferences = {
        "org.hammerspoon.Hammerspoon" = {
          MJConfigFile = "~/.config/hammerspoon/init.lua";
        };
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # User running nix-darwin
      users.users.ella = {
        name = "ella";
        home = "/Users/ella";
      };
      system.primaryUser = "ella";
    };
  in
  {
    darwinConfigurations."dogwood" = nix-darwin.lib.darwinSystem {
      modules = [
          configuration
      ];
    };
  };
}
