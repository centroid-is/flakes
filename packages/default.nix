{ pkgs }:

{
  tfc-hmi = pkgs.callPackage ./tfc-hmi { };
  pylon = pkgs.callPackage ./pylon { };
}