{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          ## This won't link, apparently the gcc-arm-embedded is a different fork?
          #crossSystem = {
          #  config = "arm-none-eabi";
          #  libc = "newlib-nano";
          #};
          config = {
            allowUnfree = true;
          };
        };
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nrf5-sdk
            gcc-arm-embedded
          ];

          SDK_ROOT = "${pkgs.nrf5-sdk}/share/nRF5_SDK";
        };
      });
}

