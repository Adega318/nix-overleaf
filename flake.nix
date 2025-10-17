{
  description = "Overleaf for nixos";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };

  /* outputs = inputs:
     inputs.flake-parts.lib.mkFlake { inherit inputs; } {
       systems = import inputs.systems;
       imports = [ ./overleaf.nix ];
     };
  */

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosModules.default = import ./overleaf.nix inputs;
  };
}
