{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          crossSystem = nixpkgs.lib.systems.examples.arm-embedded;
          config = {
            allowUnfree = true;
          };
        };
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nrf5-sdk
          ];
        };
      });
}

