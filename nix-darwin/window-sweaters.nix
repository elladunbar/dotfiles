# Window Sweaters from my fork (elladunbar/window-sweaters, hardening branch),
# which drops the startup shell script and validates Mach messages. Built from
# pinned source instead of the cask's unnotarized download, whose tap stripped
# quarantine on every update
{ pkgs, src }:
pkgs.stdenv.mkDerivation {
  pname = "window-sweaters";
  version = "1.5.0";
  inherit src;

  # Native arch only, and nixpkgs sets the deployment target
  makeFlags = [ "ARCHS=" "DEPLOY=" ];

  # Same bundle as upstream's scripts/build-app.sh; the /usr/bin tools and
  # SkyLight need the unsandboxed build
  installPhase = ''
    runHook preInstall
    app="$out/Applications/Window Sweaters.app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" AppIcon.iconset
    cp bin/borders "$app/Contents/MacOS/WindowSweaters"
    cp AppInfo.plist "$app/Contents/Info.plist"
    clang -O2 -fobjc-arc -Isrc scripts/build-icon.m -framework Cocoa -o build-icon
    ./build-icon AppIcon.iconset
    /usr/bin/iconutil -c icns AppIcon.iconset -o "$app/Contents/Resources/AppIcon.icns"
    /usr/bin/codesign --force --sign - "$app"
    runHook postInstall
  '';

  # Stripping after codesign would break the signature
  dontFixup = true;
}
