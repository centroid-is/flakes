{ pkgs, lib, stdenv, fetchurl, ... }:

let
  version = "2024.12.0";
  src = fetchurl {
    url = "https://github.com/centroid-is/linescan/releases/download/v${version}/TODO";
    sha256 = "todo";
  };
  package = stdenv.mkDerivation {
    pname = "drangey";
    inherit version src;
    sourceRoot = ".";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib  # This provides libstdc++.so.6
      pkgs.libtorch
      (import ../pylon {     # Import pylon from the same flake
        inherit pkgs lib stdenv fetchurl;
      }).package             # Get the package attribute
    ];

    installPhase = ''
      mkdir -p $out/
      cp -r * $out/
      # TODO
    '';

  };
in
{
  inherit package;

  nixosModule = { config, lib, pkgs, ... }: {
    options = {
      services.drangey.enable = lib.mkEnableOption "Drangey linescan Service";
    };

    config = lib.mkIf config.services.drangey.enable {
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

      systemd.services.drangey = {
        description = "drangey";
        serviceConfig = {
          ExecStart = "${package}/Drangey";
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
    };
  };
}