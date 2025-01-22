{ pkgs, lib, stdenv, fetchurl, wayland, libxkbcommon, fontconfig, libGL, vulkan-loader, mesa }:

let
  token = builtins.getEnv "GITHUB_TOKEN";
in if builtins.stringLength token <= 1 
then throw "GITHUB_TOKEN must be provided"
else 

let
  version = "2024.12.0";
  # ./github-asset-url.sh -t $GITHUB_TOKEN -r centroid-is/blossom -v v2024.12.0 -f shrimp-batcher.tar.gz
  src = fetchurl {
    url = "https://api.github.com/repos/centroid-is/blossom/releases/assets/213703732"; # v2024.12.0
    curlOptsList = [
      "-H" "Accept: application/octet-stream"
      "-H" "Authorization: Bearer ${token}"
    ];
    sha256 = "sha256-DmRDedDnk/+9qKX3o1AFbeIEWlpxJeEIvBVG7QBzJK4=";
    name = "shrimp-batcher.tar.gz";
  };
  package = stdenv.mkDerivation {
    pname = "shrimp-batcher";
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

    # postFixup = let
    #   rpath = lib.makeLibraryPath [
    #     wayland
    #     libxkbcommon
    #     fontconfig
    #     libGL
    #     vulkan-loader
    #     mesa
    #   ];
    # in ''
    #   patchelf --set-rpath "${rpath}" $out/example
    #   patchelf --set-rpath "${rpath}" $out/lib/libflutter_elinux_wayland.so
    #   patchelf --set-rpath "${rpath}" $out/lib/libflutter_engine.so
    # '';
  };
in
{
  inherit package;

  nixosModule = { config, lib, pkgs, ... }: {
    options = {
      services.shrimp-batcher.enable = lib.mkEnableOption "Shrimp Batcher Service";
      services.shrimp-batcher-hmi.enable = lib.mkEnableOption "Shrimp Batcher HMI Service";
    };

    config = lib.mkIf config.services.shrimp-batcher.enable {
      assertions = [
        {
          assertion = config.users.users ? tfc;
          message = "User 'tfc' must exist to run drangey service";
        }
        {
          assertion = config.users.users.tfc.group == "users";
          message = "User 'tfc' must be in group 'users'";
        }
      ];

      systemd.services.shrimp-batcher = {
        description = "shrimp-batcher";
        serviceConfig = {
          ExecStart = "${package}/shrimp-batcher";
          RuntimeDirectory = "tfc";
          RuntimeDirectoryPreserve = "yes";
          ConfigurationDirectory = "tfc";
          Restart = "always";
          RestartSec = "1s";
          StandardOutput = "journal";
          StandardError = "journal";
          LimitNOFILE = "8192";
          User = "tfc";
          Group = "users";
        };
        wantedBy = [ "default.target" ];
      };
      systemd.services.shrimp-batcher-hmi = {
        description = "shrimp-batcher-hmi";
        serviceConfig = {
          ExecStart = "${package}/hmi --bundle=${package} --fullscreen --onscreen-keyboard";
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