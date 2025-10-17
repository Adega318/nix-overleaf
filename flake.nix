{
  description = "Overleaf for nixos";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosModules = rec {
      default = overleaf;
      overleaf = import ./overleaf.nix;
    };
  };
}
