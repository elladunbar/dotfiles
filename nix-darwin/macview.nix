# Macview from my fork (elladunbar/macview, no-sparkle branch), which drops
# Sparkle so the app never fetches or installs updates on its own. Built from
# pinned source instead of the cask's unnotarized download
{ pkgs, src }:
pkgs.swiftPackages.stdenv.mkDerivation {
  pname = "macview";
  version = "0.3.3";
  inherit src;

  nativeBuildInputs = [ pkgs.swift ];

  # One module and no dependencies, so swiftc alone does what SwiftPM would
  buildPhase = ''
    runHook preBuild
    swiftc -O -swift-version 6 -module-name Macview Sources/Macview/*.swift -o Macview
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    app="$out/Applications/Macview.app/Contents"
    mkdir -p "$app/MacOS" "$app/Resources"
    cp Macview "$app/MacOS/Macview"
    cp Resources/Info.plist "$app/Info.plist"
    cp Resources/AppIcon.icns "$app/Resources/AppIcon.icns"
    runHook postInstall
  '';

  # The linker's ad-hoc signature is all an arm64 binary needs; stripping would break it
  dontStrip = true;
}
