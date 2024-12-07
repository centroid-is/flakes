{
  description = "Custom flake packages for Centroid";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      
      # Helper function to import packages
      importPackage = name: import (./packages + "/${name}") {
        inherit (nixpkgs) lib;
        inherit pkgs;
        inherit (pkgs) stdenv fetchurl wayland libxkbcommon fontconfig libGL vulkan-loader mesa;
      };
      
      # Get all directories in ./packages
      packageDirs = builtins.attrNames (builtins.readDir ./packages);
      
      # Create package set
      packages = nixpkgs.lib.genAttrs packageDirs (name: (importPackage name).package);
      
      # Create module set
      modules = nixpkgs.lib.genAttrs packageDirs (name: (importPackage name).nixosModule);
    in
    {
      packages.${system} = packages;
      nixosModules = modules;
    };
}