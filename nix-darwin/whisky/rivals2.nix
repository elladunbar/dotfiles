# Launch Rivals of Aether II from Whisky's Steam bottle with the GameCube
# adapter (via ./sdl.nix) and DXMT, working around Whisky 3.7.0 disabling d3d12
# bottle-wide (frankea/Whisky#302), which crashes the game at startup
{ pkgs }:
pkgs.writeShellApplication {
  name = "rivals2";
  text = ''
    bottle=''${RIVALS2_BOTTLE:-Steam}
    whisky=/Applications/Whisky.app/Contents/Resources/WhiskyCmd
    libs="$HOME/Library/Application Support/com.franke.Whisky/Libraries"
    wine="$libs/Wine/bin/wine"
    steam='C:\Program Files (x86)\Steam\steam.exe'
    log="$HOME/Library/Logs/rivals2.log"

    # Bottle environment as Whisky would set it; aliases and PATH aren't needed
    eval "$("$whisky" shellenv "$bottle" | grep '^export ' | grep -v '^export PATH=')"
    WINEDLLOVERRIDES=''${WINEDLLOVERRIDES//\\/}
    case ";$WINEDLLOVERRIDES;" in
      *";d3d12=;"*)
        WINEDLLOVERRIDES=$(printf %s "$WINEDLLOVERRIDES" | sed -E 's/(^|;)d3d12=(;|$)/\1d3d12=b;d3d12core=b\2/')
        ;;
      *)
        echo "rivals2: Whisky no longer disables d3d12; launching from Whisky works too" >&2
        ;;
    esac
    export WINEDLLOVERRIDES
    export DYLD_LIBRARY_PATH=/etc/whisky-sdl/lib SDL_GAMECONTROLLER_USE_BUTTON_LABELS=0

    # DXMT for the game only: the game loads these from its own folder first
    game="$WINEPREFIX/drive_c/Program Files (x86)/Steam/steamapps/common/Rivals 2/Rivals2/Binaries/Win64"
    for dll in d3d11 dxgi d3d10core; do
      cmp -s "$libs/DXMT/x64/$dll.dll" "$game/$dll.dll" || cp "$libs/DXMT/x64/$dll.dll" "$game/$dll.dll"
    done

    # A Steam started without this environment can't see the adapter and
    # would pass the game the broken d3d12 override
    if pgrep -f 'Steam\\steam\.exe' >/dev/null; then
      sdl_loaded=
      for dev in $(pgrep -f 'winedevice\.exe'); do
        lsof -p "$dev" 2>/dev/null | grep -q sdl2-libusb && sdl_loaded=1
      done
      if [ -z "$sdl_loaded" ]; then
        echo "rivals2: Windows Steam is already running without the adapter setup; quit it and run rivals2 again" >&2
        exit 1
      fi
    fi

    echo "rivals2: plug the controller into the adapter after the title screen appears" >&2
    "$wine" "$steam" -applaunch 2217000 -dx11 >>"$log" 2>&1 &

    for _ in $(seq 1 120); do
      pid=$(pgrep -f 'Rivals2-Win64-Shipping\.exe' | head -1) && break
      sleep 1
    done
    if [ -z "''${pid:-}" ]; then
      echo "rivals2: game didn't start within 2 minutes; see $log" >&2
      exit 1
    fi
    # Wine doesn't keep the display awake for games
    caffeinate -d -w "$pid"
  '';
}
