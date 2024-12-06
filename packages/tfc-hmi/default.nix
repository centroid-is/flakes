{ pkgs, lib, stdenv, fetchurl, wayland, libxkbcommon, fontconfig, libGL, vulkan-loader, mesa }:

let
  version = "2024.12.0";
  src = fetchurl {
    url = "https://github.com/centroid-is/tfc-hmi/releases/download/v${version}/example-elinux.tar.gz";
    sha256 = "278dddd44e93ff1936886a4ad7f97913fc36307ee64ab81980444837a07c3338";
  };
  tfc-hmi-bin = stdenv.mkDerivation {
    pname = "tfc-hmi-bin";
    inherit version src;
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };
in
pkgs.buildFHSUserEnv {
  name = "tfc-hmi";
  targetPkgs = pkgs: [
    wayland
    libxkbcommon
    fontconfig
    libGL
    vulkan-loader
    mesa
  ];
  runScript = "${tfc-hmi-bin}/example --bundle=${tfc-hmi-bin}";
}