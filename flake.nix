{
  description = "Patchy Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      supportSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    flake-utils.lib.eachSystem supportSystems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        deps = with pkgs; [
          sqlite
        ];
      in
      {
        packages = {
          default = pkgs.callPackage ./dist/nix/package.nix { };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
          nativeBuildInputs = deps;
          packages = with pkgs; [
            crystal_1_19
            crystal2nix
            nix-prefetch-git
            nix
            nixfmt
            nixd
          ];
          # sqlite library needs to be in the LD_LIBRARY_PATH environment variable
          # so crystal can detect it in the linking stage.
          shellHook = ''
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath deps}"
          '';
        };
      }
    )
    // {
      nixosModules.default = import ./dist/nix/module.nix self;
    };
}
