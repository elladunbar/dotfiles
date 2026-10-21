{
  description = "MacOS configuration for dogwood";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Last release with x86_64-darwin, for Whisky's x86_64 Wine
    nixpkgs-x86.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-mono = {
      url = "github:badlogic/pi-mono";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin-x64.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-x86, nix-claude-code, nix-darwin, pi-mono, ... }:
  let
    # Keep dotfiles out of $HOME, for shells and GUI apps alike
    xdgDirs = {
      XDG_BIN_HOME = "/Users/ella/.local/bin";
      XDG_CACHE_HOME = "/Users/ella/Library/Caches";
      XDG_CONFIG_HOME = "/Users/ella/.config";
      XDG_DATA_HOME = "/Users/ella/.local/share";
      XDG_RUNTIME_DIR = "$(getconf DARWIN_USER_TEMP_DIR)";
      XDG_STATE_HOME = "/Users/ella/.local/state";
    };
    xdgVars = xdgDirs // (with xdgDirs; {
      CARGO_HOME = "${XDG_DATA_HOME}/cargo";
      CLAUDE_CONFIG_DIR = "${XDG_CONFIG_HOME}/claude";
      DOCKER_CONFIG = "${XDG_CONFIG_HOME}/docker";
      GEM_HOME = "${XDG_DATA_HOME}/gem";
      GEM_SPEC_CACHE = "${XDG_CACHE_HOME}/gem";
      INPUTRC = "${XDG_CONFIG_HOME}/readline/inputrc";
      IPYTHONDIR = "${XDG_CONFIG_HOME}/ipython";
      LESSHISTFILE = "${XDG_STATE_HOME}/less/history";
      MPLCONFIGDIR = "${XDG_CONFIG_HOME}/matplotlib";
      NPM_CONFIG_CACHE = "${XDG_CACHE_HOME}/npm";
      NPM_CONFIG_USERCONFIG = "${XDG_CONFIG_HOME}/npm/npmrc";
      NVM_DIR = "${XDG_DATA_HOME}/nvm";
      PI_CODING_AGENT_DIR = "${XDG_CONFIG_HOME}/pi/agent";
      PYTHON_HISTORY = "${XDG_STATE_HOME}/python/history";
      RUSTUP_HOME = "${XDG_DATA_HOME}/rustup";
      R_ENVIRON_USER = "${XDG_CONFIG_HOME}/R/Renviron";
      SQLITE_HISTORY = "${XDG_STATE_HOME}/sqlite/history";
      STARSHIP_CACHE = "${XDG_CACHE_HOME}/starship";
      WGETRC = "${XDG_CONFIG_HOME}/wget/wgetrc";
      WORKON_HOME = "${XDG_DATA_HOME}/virtualenvs";
    });

    # PATH for GUI apps and other launchd services
    guiPath = with xdgVars; nixpkgs.lib.concatStringsSep ":" [
      XDG_BIN_HOME
      "${CARGO_HOME}/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];

    configuration = { config, lib, pkgs, ... }: {
      # Put config in home folder
      environment.etc.nix-darwin.source = "/Users/ella/.config/nix-darwin";

      # XDG variables for shells (dash reads this from ~/.profile)
      environment.variables = xdgVars;
      environment.etc.set-environment.source = config.system.build.setEnvironment;

      # Overlays
      nixpkgs.overlays = [
        nix-claude-code.overlays.default
        pi-mono.overlays.default
      ];

      # Fish theme that follows the terminal's light/dark mode
      environment.etc."fish/themes/nightfox.theme".source =
        pkgs.runCommand "nightfox.theme" { nativeBuildInputs = [ pkgs.fish ]; } ''
          export HOME=$TMPDIR
          {
            echo "# name: 'Nightfox (dayfox/duskfox)'"
            for variant in light:dayfox dark:duskfox; do
              mode=''${variant%%:*}
              style=''${variant#*:}
              printf '\n[%s]\n' "$mode"
              fish --no-config -c 'source $argv[1]
                for v in (set -n | string match -r "^fish_(?:pager_)?color_.*")
                  echo $v $$v
                end' ${pkgs.vimPlugins.nightfox-nvim}/extra/$style/$style.fish
            done
          } > $out
        '';

      # SDL with libusb for GameCube adapter in Whisky (DYLD_LIBRARY_PATH=/etc/whisky-sdl/lib)
      environment.etc.whisky-sdl.source =
        import ./whisky/sdl.nix { pkgs = nixpkgs-x86.legacyPackages.x86_64-darwin; };

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
        air-formatter
        b2sum
        bash
        bash-language-server
        bat
        bitwarden-cli
        btop
        ccache
        chafa
        clang-tools
        claude-code
        cmake
        colima
        dash
        docker
        dos2unix
        exiftool
        eza
        fastfetch
        fd
        ffmpeg
        fish
        fzf
        gh
        git
        git-filter-repo
        git-lfs
        git-xet
        glab
        glow
        gnused
        go
        hexyl
        imagemagick
        jdt-language-server
        julia-bin
        lua-language-server
        lynx
        magic-wormhole
        man
        mas
        minhtml
        mold
        mosh
        neovim
        ninja
        nmap
        openconnect
        openssl
        pandoc
        perl
        perlnavigator
        php
        pi
        poppler
        rclone
        ripgrep
        rsync
        ruff
        rustup
        socat
        sqlcmd
        starship
        stow
        stylua
        svgo
        tailscale
        tealdeer
        texinfo
        texlab
        tmux
        ty
        typst
        uv
        vscode-langservers-extracted
        wget
        yazi
        zellij
        zstd
        zulu25

        lua51Packages.lua
        lua51Packages.luarocks

        (pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            colorspace
            ggh4x
            ggthemes
            gt
            gtExtras
            languageserver
            patchwork
            psych
            readxl
            reticulate
            tidyverse
            webshot2
          ];
        })

        (import ./whisky/rivals2.nix { inherit pkgs; })
      ];

      # Homebrew
      homebrew = {
        enable = true;
        prefix = "/opt/homebrew";
        onActivation.autoUpdate = true;
        onActivation.cleanup = "uninstall";
        onActivation.upgrade = true;
        onActivation.extraFlags = [ "--force-cleanup" ];
        taps = [
          {
            name = "frankea/whisky";
            trusted = true;
          }
          {
            name = "jurplel/tap";
            trusted = true;
          }
          {
            name = "microsoft/mssql-release";
            trusted = true;
          }
        ];
        brews = [
          "mpv"
          "msodbcsql18"
          "tree-sitter-cli"
          "unixodbc"
        ];
        casks = [
          "anki"
          "box-drive"
          "calibre"
          "citrix-workspace"
          "discord"
          "element"
          "firefox"
          "frankea/whisky/whisky"
          "ghostty"
          "gimp"
          "google-chrome"
          "hammerspoon"
          "handy"
          "instant-space-switcher"
          "localsend"
          "mactex"
          "microsoft-office"
          "moonlight"
          "netnewswire"
          "obs"
          "onlyoffice"
          "orion"
          "prism"
          "prismlauncher"
          "raycast"
          "readest"
          "sioyek"
          "spotify"
          "steam"
          "syncthing-app"
          "transmission"
          "zoom"
          "zotero"
        ];
        masApps = {
          Bitwarden = 1352778147;
          "Consent-O-Matic" = 1606897889;
          Keynote = 409183694;
          Numbers = 409203825;
          Pages = 409201541;
        };
      };

      # Launch services
      launchd.agents = { # supposed to run as current user
        # XDG variables for GUI apps, re-applied at every login
        "xdg-env" = {
          serviceConfig = {
            Program = "${pkgs.writeShellScript "xdg-env" ''
              mkdir -p ${xdgVars.XDG_STATE_HOME}/{python,sqlite,wget}
              ${lib.concatStrings (lib.mapAttrsToList (name: value: ''
                launchctl setenv ${name} "${value}"
              '') xdgVars)}
            ''}";
            RunAtLoad = true;
            UserName = "ella";
          };
        };
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
        "rclone-cloud" = {
          environment = { "HOME" = "/Users/ella"; };
          path = [
            "/sbin"
            "/usr/sbin"
            "/usr/bin"
          ];
          serviceConfig = {
            ProgramArguments = [
                # clear a stale mount left by a dead rclone, otherwise the restart fails with "already mounted"
                "${pkgs.writeShellScript "rclone-cloud" ''
                  if mount | grep -q " on /Users/ella/Cloud "; then
                    umount -f /Users/ella/Cloud || diskutil unmount force /Users/ella/Cloud
                  fi
                  exec "$@"
                ''}"
                "${pkgs.rclone}/bin/rclone"
                "nfsmount" "cloud:" "/Users/ella/Cloud"
                "--vfs-cache-mode" "full"
                "--vfs-cache-max-size" "20G"
                "--vfs-cache-max-age" "720h"
                "--dir-cache-time" "30s"
                # fail fast when the server is down instead of hanging the mount
                "--contimeout" "5s"
                "--timeout" "30s"
                "--low-level-retries" "2"
            ];
            KeepAlive = true;
            RunAtLoad = true;
            StandardErrorPath = "/Users/ella/Library/Caches/org.nixos.rclone-cloud/rclone-cloud_error.log";
            StandardOutPath = "/Users/ella/Library/Caches/org.nixos.rclone-cloud/rclone-cloud.log";
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
                "--ui-mcp-proxy"
                "--n-gpu-layers" "all"
                "--flash-attn" "on"
                "--load-mode" "none"
                "--parallel" "1"
                "--kv-unified"
                "--cache-type-k" "q8_0"
                "--cache-type-v" "q8_0"
                "--cache-type-k-draft" "f16"
                "--cache-type-v-draft" "f16"
                "--batch-size" "1024"
                "--ubatch-size" "512"
                "--spec-default"
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

      # Replaces a stale PATH migrated from an old Mac; launchd applies it at boot
      system.activationScripts.postActivation.text = ''
        launchctl config user path ${lib.escapeShellArg guiPath}
      '';

      # System settings
      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };
      services.openssh.extraConfig = ''
        PermitRootLogin no
        PasswordAuthentication no
        KbdInteractiveAuthentication no
      '';
      system.defaults.CustomUserPreferences = {
        "org.hammerspoon.Hammerspoon" = {
          MJConfigFile = "~/.config/hammerspoon/init.lua";
        };
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Keep profiles in ~/.local/state/nix rather than ~/.nix-profile and ~/.nix-defexpr
      nix.settings.use-xdg-base-directories = true;
      nix.channel.enable = false;

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
