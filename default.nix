let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
{
  tfc-hmi = pkgs.callPackage ./packages/tfc-hmi { };
  pylon = pkgs.callPackage ./packages/pylon { };
}