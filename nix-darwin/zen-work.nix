# Copy of Zen.app with its own bundle ID and a UAB green icon, so the Work
# profile gets a separate Dock icon; rebuilt when Zen or this script changes
{ pkgs }:
pkgs.writeShellScript "zen-work" ''
  set -euo pipefail
  src=/Applications/Zen.app
  dst="/Applications/Zen Work.app"
  plist=/usr/libexec/PlistBuddy
  [ -d "$src" ] || exit 0

  stamp="$($plist -c 'Print :CFBundleVersion' "$src/Contents/Info.plist") $0"
  if [ "$($plist -c 'Print :ZenWorkStamp' "$dst/Contents/Info.plist" 2>/dev/null)" = "$stamp" ]; then
    exit 0
  fi
  if pgrep -f "$dst/Contents/MacOS/" >/dev/null; then
    echo "zen-work: Zen Work is running, quit it and rebuild to update it" >&2
    exit 0
  fi
  echo "zen-work: building $dst" >&2

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  app="$tmp/Zen Work.app"
  info="$app/Contents/Info.plist"
  ditto "$src" "$app"

  # A different bundle ID makes the Dock and LaunchServices treat it as its own app
  $plist -c 'Set :CFBundleIdentifier app.zen-browser.zen.work' "$info"
  $plist -c 'Set :CFBundleName Zen Work' "$info"
  $plist -c 'Delete :CFBundleDisplayName' "$info" 2>/dev/null || true
  $plist -c "Add :ZenWorkStamp string $stamp" "$info"

  # The in-app updater would undo these changes; this copy follows Zen.app instead
  mkdir -p "$app/Contents/Resources/distribution"
  echo '{"policies":{"DisableAppUpdate":true}}' > "$app/Contents/Resources/distribution/policies.json"

  # Recolor the icon: Zen's #202020 background becomes UAB green (#1A5632), the rings stay cream
  /usr/bin/iconutil -c iconset -o "$tmp/icon.iconset" "$app/Contents/Resources/firefox.icns"
  for png in "$tmp"/icon.iconset/*.png; do
    ${pkgs.imagemagick}/bin/magick "$png" -channel RGB -level 12.5%,94.9% \
      \( -size 1x256 gradient:'#1A5632-#F2F0E3' \) -clut +channel "$png"
  done
  /usr/bin/iconutil -c icns -o "$app/Contents/Resources/firefox.icns" "$tmp/icon.iconset"

  # Editing the bundle breaks Zen's signature; ad-hoc re-sign without its entitlements,
  # since restricted ones (application-identifier, passkeys) block launch when ad-hoc signed
  xattr -cr "$app"
  codesign --force --deep --sign - "$app"

  rm -rf "$dst"
  mv "$app" "$dst"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$dst"
''
