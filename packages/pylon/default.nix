{ pkgs, lib, stdenv, fetchurl, ... }:

let
  version = "8.0.2.16314";
  src = fetchurl {
    url = "https://downloadbsl.blob.core.windows.net/software/pylon-${version}_linux-x86_64_setup.tar.gz";
    sha256 = "1395b2474ecb5cb06d22d2fd7486378638c0d18465c40ce7aaf9ce62a7d0a1b6"
  };
  package = stdenv.mkDerivation {
    pname = "pylon";
    inherit version src;
    sourceRoot = ".";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
    ];

    unpackPhase = ''
      tar xf $src
      mkdir artifacts
      cd artifacts
      tar xf ../pylon-${version}_linux-x86_64.tar.gz
    '';

    installPhase = ''
      mkdir -p $out
      cp -r artifacts/* $out/
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