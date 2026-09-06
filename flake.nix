{
<<<<<<< HEAD
  description = "http3-ytproxy NixOS Flake";
=======
  description = "Patchy Nix Flake";
>>>>>>> upstream/master

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
<<<<<<< HEAD
=======
        deps = with pkgs; [
          sqlite
        ];
>>>>>>> upstream/master
      in
      {
        packages = {
          default = pkgs.callPackage ./dist/nix/package.nix { };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
<<<<<<< HEAD
          packages = with pkgs; [
            crystal_1_19
=======
          nativeBuildInputs = deps;
          packages = with pkgs; [
            crystal_1_19
            libllvm
            libffi
>>>>>>> upstream/master
            crystal2nix
            nix-prefetch-git
            nix
            nixfmt
            nixd
<<<<<<< HEAD
          ];
=======
            # for libmagic!
            file
            esbuild
          ];
          # sqlite library needs to be in the LD_LIBRARY_PATH environment variable
          # so crystal can detect it in the linking stage.
          shellHook = ''
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath deps}"
          '';
>>>>>>> upstream/master
        };
      }
    )
    // {
      nixosModules.default = import ./dist/nix/module.nix self;
    };
}
