# Verify the build
```bash
nix flake check  # Verify the flake please remember to commit before checking
nix build .#tfc-hmi  # Build the package
```
# Update the flake lock file
```bash
nix flake lock
# or todo
nix flake lock --update-input nixpkgs
```

# Use the package

## flake.nix
Add to your flake.nix:
```nix
inputs.tfc-packages.url = "github:centroid-is/flakes";  # Uses latest release
```

Or pin to a specific version:
```nix
inputs.tfc-packages.url = "github:centroid-is/flakes?ref=v2024.12.2";
```

Make packages available to configuration.nix, in your flake.nix, specify `specialArgs`:
```nix
outputs = inputs: {
  nixosConfigurations = {
    tfc = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit (inputs) tfc-packages;
      };
    };
  };
};
```
## configuration.nix

At the top of your configuration.nix, declare the package:
```nix
{ tfc-packages, ... }:
```

Then import specific module as needed:
```nix
{
  imports = [
    tfc-packages.nixosModules.tfc-hmi
  ];
}
```

Then if systemd is used, enable the service:
```nix
{
  services.tfc-hmi.enable = true;
}
```

Install the package for a user:
```nix
  users.users.tfc = {
    isNormalUser = true;
    packages = with pkgs; [
      tfc-packages.packages.x86_64-linux.tfc-hmi
    ];
  };
```
Or use systemPackages:
```nix
  environment.systemPackages = with pkgs; [
    tfc-packages.packages.x86_64-linux.tfc-hmi
  ];
```

## Install

```bash
sudo nixos-rebuild switch
```

# Packaging

Please see https://nixos.wiki/wiki/Packaging/Binaries for more information.
