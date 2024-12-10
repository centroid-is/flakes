{ pkgs, lib, stdenv, fetchurl, wayland, libxkbcommon, fontconfig, libGL, vulkan-loader, mesa }:

let
  version = "2024.12.0";
  src = fetchurl {
    url = "https://github.com/centroid-is/tfc-hmi/releases/download/v${version}/example-elinux.tar.gz";
    sha256 = "278dddd44e93ff1936886a4ad7f97913fc36307ee64ab81980444837a07c3338";
  };
  package = stdenv.mkDerivation {
    pname = "tfc-hmi-bin";
    inherit version src;
    sourceRoot = ".";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      wayland
      libxkbcommon
      fontconfig
      libGL
      vulkan-loader
      mesa
    ];

    installPhase = ''
      mkdir -p $out/
      cp -r * $out/
    '';

    postFixup = let
      rpath = lib.makeLibraryPath [
        wayland
        libxkbcommon
        fontconfig
        libGL
        vulkan-loader
        mesa
      ];
    in ''
      patchelf --set-rpath "${rpath}" $out/example
      patchelf --set-rpath "${rpath}" $out/lib/libflutter_elinux_wayland.so
      patchelf --set-rpath "${rpath}" $out/lib/libflutter_engine.so
    '';
  };
in
{
  inherit package;

  nixosModule = { config, lib, pkgs, ... }: {
    options = {
      services.tfc-hmi.enable = lib.mkEnableOption "TFC HMI Service";
    };

    config = lib.mkIf config.services.tfc-hmi.enable {
      assertions = [
        {
          assertion = config.users.users ? tfc;
          message = "User 'tfc' must exist to run tfc-hmi service";
        }
        {
          assertion = config.users.users.tfc.group == "users";
          message = "User 'tfc' must be in group 'users'";
        }
      ];

      systemd.services.tfc-hmi = {
        description = "tfc-hmi";
        serviceConfig = {
          ExecStart = "${package}/example --bundle=${package}";
          RuntimeDirectory = "tfc";
          User = "tfc";
          Group = "users";
          Restart = "always";
          RestartSec = "3s";
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