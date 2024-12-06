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
  package = pkgs.buildFHSUserEnv {
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
  };
in
{
  # Export the package
  inherit package;

  # NixOS module for the service
  nixosModule = { config, lib, pkgs, ... }: {
    options = {
      services.tfc-hmi.enable = lib.mkEnableOption "TFC HMI Service";
    };

    config = lib.mkIf config.services.tfc-hmi.enable {
      users.users.tfc = {
        isSystemUser = true;
        group = "users";
      };

      systemd.services.tfc-hmi = {
        description = "tfc-hmi";
        serviceConfig = {
          ExecStart = "${package}/bin/tfc-hmi";
          RuntimeDirectory = "tfc";
          User = "tfc";
          Group = "users";
        };
        environment = {
          WAYLAND_DISPLAY = "wayland-1";
          XDG_RUNTIME_DIR = "/run/user/1000"; # todo get 1000 from user
        };
        after = [ "weston.service" ];
        wantedBy = [ "default.target" ];
      };
    };
  };
}