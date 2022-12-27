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

        bin2uf2 = pkgs.stdenv.mkDerivation rec {
          pname = "bin2uf2";
          version = "3.4.0";

          src = pkgs.fetchFromGitHub {
            owner = "microsoft";
            repo = "uf2-samdx1";
            rev = "v${version}";
            sha256 = "b1/SnLsSK7uAwECDgJIOtD67M7TZ7NS0PFY6arCUW5I=";
          };

          dontBuild = true;
          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            substitute scripts/bin2uf2.js $out/bin/bin2uf2.js \
              --replace '/usr/bin/env node' '${pkgs.nodejs}/bin/node'
            chmod +x $out/bin/bin2uf2.js

            runHook postInstall
          '';
        };

      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            gcc-arm-embedded
            nrf5-sdk

            usbutils
            bin2uf2
            #pkgs.python310Packages.adafruit-nrfutil
            minicom
          ];

          SDK_ROOT = "${pkgs.nrf5-sdk}/share/nRF5_SDK";
        };
      });
}

