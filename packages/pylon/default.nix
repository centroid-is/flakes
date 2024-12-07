{ pkgs, lib, stdenv, fetchurl, ... }:

let
  version = "8.0.2.16314";
  src = fetchurl {
    url = "https://downloadbsl.blob.core.windows.net/software/pylon-${version}_linux-x86_64_setup.tar.gz";
    sha256 = "1395b2474ecb5cb06d22d2fd7486378638c0d18465c40ce7aaf9ce62a7d0a1b6";
  };
  package = stdenv.mkDerivation {
    pname = "pylon";
    inherit version src;
    sourceRoot = ".";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib  # This provides libstdc++.so.6
      pkgs.libGL             # For libGLX.so.0 and libOpenGL.so.0 and libEGL.so.1
      pkgs.glib             # For libgio-2.0.so.0, libgobject-2.0.so.0, libglib-2.0.so.0
      pkgs.libuuid          # For libuuid.so.1
      pkgs.zlib             # For libz.so.1
      pkgs.xz               # For liblzma.so.5
    #   pkgs.libX11            # For libX11.so.6
      pkgs.xorg.xcbutilcursor
      pkgs.xorg.xcbutilimage
      pkgs.xorg.xcbutilkeysyms
      pkgs.xorg.xcbutilrenderutil
      pkgs.xorg.xcbutilwm        # This provides libxcb-icccm.so.4
      pkgs.xorg.libxcb
      pkgs.xorg.libSM        # For libSM.so.6
      pkgs.xorg.libICE       # For libICE.so.6
      pkgs.libtiff          # For libtiff.so.5
    ];

    unpackPhase = ''
      tar xf $src
      mkdir artifacts
      cd artifacts
      tar xf ../pylon-${version}_linux-x86_64.tar.gz
      cd ..
    '';

    installPhase = ''
      mkdir -p $out
      cp -r artifacts/* $out/
    '';

    preFixup = ''
      echo "Patching Qt tiff plugin..."
      patchelf --replace-needed libtiff.so.5 libtiff.so.6 $out/lib/Qt/res/archdatadir/plugins/imageformats/libqtiff.so
    '';

    meta = with lib; {
      description = "Basler Pylon Camera Software Suite";
      homepage = "https://www.baslerweb.com/en/products/software/basler-pylon-camera-software-suite/";
      license = licenses.unfree;
      platforms = platforms.linux;
    };
  };
in
{
  inherit package;
  nixosModule = { config, lib, pkgs, ... }: {
    options = {};
    config = {};
  };
}