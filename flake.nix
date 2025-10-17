{
  description = "Overleaf for nixos";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosModules = rec {
      default = overleaf;
      overleaf = import ./overleaf.nix;
    };
  };
}
