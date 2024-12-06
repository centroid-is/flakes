{
  description = "Custom flake for tfc-hmi";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      version = "2024.12.0";
      src = pkgs.fetchurl {
        url = "https://github.com/centroid-is/tfc-hmi/releases/download/v${version}/example-elinux.tar.gz";
        sha256 = "278dddd44e93ff1936886a4ad7f97913fc36307ee64ab81980444837a07c3338";
      };
      tfc-hmi-bin = pkgs.stdenv.mkDerivation {
        pname = "tfc-hmi-bin";
        version = version;
        src = src;
        sourceRoot = ".";
        installPhase = ''
          mkdir -p $out
          cp -r * $out/
        '';
      };
    in {
      packages.x86_64-linux.tfc-hmi = pkgs.buildFHSUserEnv {
        name = "tfc-hmi";
        targetPkgs = pkgs: [
          pkgs.wayland
          pkgs.libxkbcommon
          pkgs.fontconfig
          pkgs.libGL
          pkgs.vulkan-loader
          pkgs.mesa
        ];
        runScript = "${tfc-hmi-bin}/example --bundle=${tfc-hmi-bin}";
      };
    };
}