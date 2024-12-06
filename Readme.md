# Verify the build
```
nix flake check  # Verify the flake please remember to commit before checking
nix build .#tfc-hmi  # Build the package
```
# Update the flake lock file
```
nix flake lock
# or todo
nix flake lock --update-input nixpkgs
```
