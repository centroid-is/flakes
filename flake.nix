{
  description = "Custom flake for tfc-hmi";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux = import ./packages {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    };
  };
}