{ config, lib, pkgs, ... }:
# Game streaming. Sunshine captures a headless sway over wlr-screencopy, and
# before every stream the sway output is resized to the Moonlight client's
# exact resolution and refresh rate. Both run as ella's user services; linger
# starts that user manager at boot, so nothing has to log in.
let
  systemctl = "${config.systemd.package}/bin/systemctl";
  swaymsg = lib.getExe' pkgs.sway "swaymsg";
  dash = lib.getExe pkgs.dash;
  # pkgs.dash only ships bin/dash, but sway looks up `sh` by name
  dashAsSh = pkgs.runCommand "dash-as-sh" { } ''
    mkdir -p $out/bin
    ln -s ${dash} $out/bin/sh
  '';

  swayConfig = pkgs.writeText "sway-headless.conf" ''
    # placeholder until the first client connects; see global_prep_cmd
    output HEADLESS-1 mode --custom 1920x1080@60Hz

    default_border none
    # every tiled window (Big Picture, a game) takes the whole output, so a
    # game launched from Steam doesn't end up side by side with it. dialogs
    # float and are left alone
    for_window [tiling] fullscreen enable

    xwayland enable

    # give the user manager this session's sockets, then tell systemd sway is
    # up; graphical-session.target, and Sunshine after it, waits for this
    exec ${systemctl} --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK && ${config.systemd.package}/bin/systemd-notify --ready
  '';
in
{
  users.users.ella = {
    linger = true;
    # there's no logind seat session, so uaccess tags never apply. the groups
    # stand in for them: input for sway's libinput backend and Sunshine's
    # virtual pads (which Steam also reads), uinput because hardware.uinput's
    # rule overrides Sunshine's group for /dev/uinput, and video because
    # Sunshine opens /dev/dri/card1 to hand captured frames to CUDA/NVENC
    # (without it, it silently falls back to libx264)
    extraGroups = [
      "input"
      "uinput"
      "video"
    ];
  };

  systemd.user.services.sway-headless = {
    description = "Headless sway for Sunshine";
    unitConfig.ConditionUser = "ella";
    wantedBy = [ "default.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    bindsTo = [ "graphical-session.target" ];
    before = [ "graphical-session.target" ];
    # sway runs `exec` lines with execlp("sh"), and NixOS user units get a
    # minimal PATH without it
    path = [ dashAsSh ];
    environment = {
      # headless for the output, libinput for Sunshine's uinput devices
      WLR_BACKENDS = "headless,libinput";
      # don't exit if there are no input devices yet
      WLR_LIBINPUT_NO_DEVICES = "1";
      WLR_RENDER_DRM_DEVICE = "/dev/dri/renderD128";
      # no seat session to ask; open devices directly, via the groups above
      LIBSEAT_BACKEND = "noop";
    };
    serviceConfig = {
      # ready comes from systemd-notify at the end of swayConfig
      Type = "notify";
      NotifyAccess = "all";
      ExecStart = "${lib.getExe pkgs.sway} --unsupported-gpu --config ${swayConfig}";
      ExecStopPost = "${systemctl} --user unset-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  services.sunshine = {
    enable = true;
    # without CUDA, Sunshine can't hand wlr-captured frames to NVENC.
    # cudaSupport is per package here (see configuration.nix), so turn it on
    package = pkgs.sunshine.override { cudaSupport = true; };
    autoStart = true;
    # the lan-only rules in configuration.nix already cover these ports
    openFirewall = false;
    settings = {
      capture = "wlr";
      encoder = "nvenc";
      # the firewall has v6 rules for these ports too
      address_family = "both";
      # HEVC Main only; HDR isn't possible with this capture path, so don't
      # offer Main10
      hevc_mode = 2;
      # match the virtual output to the client before every app
      global_prep_cmd = builtins.toJSON [
        {
          do = "${dash} -c \"${swaymsg} -- output HEADLESS-1 mode --custom \${SUNSHINE_CLIENT_WIDTH}x\${SUNSHINE_CLIENT_HEIGHT}@\${SUNSHINE_CLIENT_FPS}Hz\"";
          undo = "";
        }
      ];
    };
    applications.apps = [
      {
        name = "Steam Big Picture";
        cmd = "${config.programs.steam.package}/bin/steam -gamepadui";
        image-path = "steam.png";
      }
    ];
  };

  # graphical-session.target is only ordered after sway, so it's reached even
  # when sway fails to start, and Sunshine would come up with no display and
  # sit there. tie it to sway directly instead: it only runs while sway is up,
  # and every start or restart of sway brings it back
  systemd.user.services.sunshine = {
    bindsTo = [ "sway-headless.service" ];
    after = [ "sway-headless.service" ];
    wantedBy = [ "sway-headless.service" ];
  };

  # the Sunshine module turns avahi on, and avahi opens 5353 on every
  # interface. clients add the host by address instead
  services.avahi.enable = false;

  # Sunshine makes its own virtual sink through the pulse API
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  programs.steam.enable = true;
}
