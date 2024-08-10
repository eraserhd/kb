{
  description = "Retro soldering iron";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        add-missing = pkgs.callPackage ./derivation.nix {};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = (with pkgs.pkgsCross.avr.buildPackages; [
            binutils
            gcc8
          ]) ++ (with pkgs; [
            avrdude
          ]);
        };
    });
}
