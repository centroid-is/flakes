{ pkgs, lib, stdenv, fetchurl, runCommand, bash, curl, wget, jq, downloadScript, ... }:

let
  version = "2024.12.1";
  src = let
    token = builtins.getEnv "GITHUB_TOKEN";
  in runCommand "drangey-${version}.tar.gz" {
    nativeBuildInputs = [ bash curl wget jq ];
    inherit token;
  } ''
    bash ${downloadScript} \
      -t $token \
      -r centroid-is/linescan \
      -v v${version} \
      -f linescan-${version}-Linux-x86_64-Drangey.tar.gz \
      -o $out
  '';
  package = stdenv.mkDerivation {
    pname = "drangey";
    inherit version src;
    sourceRoot = ".";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib  # This provides libstdc++.so.6
      (import ../pylon {     # Import pylon from the same flake
        inherit pkgs lib stdenv fetchurl;
      }).package             # Get the package attribute
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp -r usr/local/bin/Drangey $out/bin/Drangey
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
          ExecStart = "${package}/bin/Drangey";
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