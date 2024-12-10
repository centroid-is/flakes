{ pkgs, lib, stdenv, fetchurl, ... }:

let
  token = builtins.getEnv "GITHUB_TOKEN";
in if builtins.stringLength token <= 1 
then throw "GITHUB_TOKEN must be provided"
else 

let
  version = "2024.12.0";
  # ./github-asset-url.sh -t $GITHUB_TOKEN -r centroid-is/linescantrain -v v2024.12.0 -f best_model.pt
  src = fetchurl {
    url = "https://api.github.com/repos/centroid-is/linescantrain/releases/assets/212239925"; # v2024.12.0
    curlOptsList = [
      "-H" "Accept: application/octet-stream"
      "-H" "Authorization: Bearer ${token}"
    ];
    sha256 = "sha256-zHPEReUo3e9LKvs9oSab4Y/54dN40K9efORv0qDxFUg=";
    name = "best_model.pt";
  };
  package = stdenv.mkDerivation {
    pname = "linescan-model";
    inherit version src;
    dontUnpack = true;
    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/
      cp $src $out/best_model.pt
      # todo is this the way?
    '';
  };
in
{
  inherit package;

  nixosModule = { config, lib, pkgs, ... }: {
    options = {};
    config = {
      environment.etc."linescan/best_model.pt" = {
        source = "${package}/best_model.pt";
      };
    };
  };
}