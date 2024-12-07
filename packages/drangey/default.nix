{ pkgs, lib, stdenv, fetchurl, runCommand, bash, curl, wget, jq, downloadScript, ... }:

let
  version = "2024.12.1";
  src = let
    token = builtins.getEnv "GITHUB_TOKEN";
    filename = "linescan-${version}-Linux-x86_64-Drangey.tar.gz";
    
    # First, fetch the release information
    releaseInfo = builtins.fromJSON (builtins.readFile (fetchurl {
      url = "https://api.github.com/repos/centroid-is/linescan/releases";
      curlOptsList = [ "-H" "Authorization: Bearer ${token}" "-H" "Accept: application/vnd.github.v3.raw" ];
      sha256 = "sha256-gdtycuTprwGLW7eRgmp3HkboXymlvHOj0r934qmoFFM=";
    }));
    
    # Find the correct release and asset
    release = builtins.head (builtins.filter (r: r.tag_name == "v${version}") releaseInfo);
    asset = builtins.head (builtins.filter (a: a.name == filename) release.assets);
    
  in fetchurl {
    name = "drangey.tar.gz";
    url = "https://api.github.com/repos/centroid-is/linescan/releases/assets/${toString asset.id}";
    curlOptsList = [ "-H" "Accept: application/octet-stream" "-H" "Authorization: Bearer ${token}" ];
    sha256 = "sha256-kgu1rXxwKksyihAtk0YooGmfZtyu5irlweRQuF3wAQ4=";
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
      (import ../pylon {     # Import pylon from the same flake
        inherit pkgs lib stdenv fetchurl;
      }).package             # Get the package attribute
      pkgs.python3Packages.pytorch  # Add PyTorch for libtorch_cpu.so and libc10.so
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