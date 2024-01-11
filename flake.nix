{
  description = "A very basic flake";

  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://cache.iog.io" ];
    extra-trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
    allow-import-from-derivation = "true";
    max-jobs = "auto";
    auto-optimise-store = "true";
  };  

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ nixpkgs, flake-parts, haskellNix, ... }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      perSystem = { options, config, self', inputs', lib, system, ... }:
        let
          # Need this to use haskell.nix. This adds overlay and config to the nixpkgs.
          pkgs = import nixpkgs {
            overlays = [ haskellNix.overlay ];
            inherit system;
            inherit (haskellNix) config;
          };

          project = pkgs.haskell-nix.project' {
            src = ./.;
            compiler-nix-name = "ghc928";

            shell = {
              nativeBuildInputs = with pkgs; [
                act
              ];
            };
          };
          flake = project.flake { };
        in
          { inherit (flake) packages devShells; } // {
            # This is how more packages can be added.
            # One can build a docker container, shell script, and
            # other stuff like this.
            packages.sayHello =
              pkgs.writeShellScript "helloWorld" ''
              echo "hello world"
            '';
          };
    };
}
