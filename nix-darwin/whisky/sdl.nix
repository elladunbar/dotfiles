# x86_64 SDL2 with libusb HIDAPI so Whisky's Wine can read a GameCube adapter
# in Wii U mode; point a bottle's DYLD_LIBRARY_PATH at $out/lib
{ pkgs }:
let
  sdl = pkgs.stdenv.mkDerivation {
    pname = "sdl2-libusb";
    version = "2.32.10";
    src = pkgs.fetchFromGitHub {
      owner = "libsdl-org";
      repo = "SDL";
      rev = "release-2.32.10";
      hash = "sha256-aG8q/z7kGy2CUHe+sR20ze55zMVF5ZqIArgbZB1CJDo=";
    };
    patches = [ ./sdl-libusb-detach.patch ];
    nativeBuildInputs = with pkgs; [ cmake ninja pkg-config ];
    buildInputs = [ pkgs.libusb1 ];
    cmakeFlags = [
      "-DSDL_HIDAPI=ON"
      "-DSDL_HIDAPI_LIBUSB=ON"
      "-DSDL_SHARED=ON"
      "-DSDL_STATIC=OFF"
      "-DSDL_TEST=OFF"
    ];
    # Malformed paths fail fixup's check, and nothing here needs it
    postInstall = "rm -r $out/lib/pkgconfig";
  };
in
pkgs.runCommand "whisky-sdl" { } ''
  mkdir -p $out/lib
  ln -s ${sdl}/lib/libSDL2-2.0.0.dylib $out/lib/
  ln -s ${pkgs.libusb1.out}/lib/libusb-1.0.0.dylib $out/lib/
  ln -s libusb-1.0.0.dylib $out/lib/libusb-1.0.dylib
''
