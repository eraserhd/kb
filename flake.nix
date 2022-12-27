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

        uf2conv-py = pkgs.stdenv.mkDerivation rec {
          pname = "uf2conv-py";
          version = "3.2.0";

          src = pkgs.fetchFromGitHub {
            owner = "zephyrproject-rtos";
            repo = "zephyr";
            rev = "zephyr-v${version}";
            sha256 = "pNZgMd2zSVFCAoCG7LEV+o2wUYGr38b/EutszjEdDAc=";
          };

          dontBuild = true;
          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            substitute scripts/build/uf2conv.py $out/bin/uf2conv.py \
              --replace '/usr/bin/env python3' '${pkgs.python310}/bin/python3'
            chmod +x $out/bin/uf2conv.py

            runHook postInstall
          '';
        };

      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            gcc-arm-embedded
            nrf5-sdk
            uf2conv-py

            usbutils
            pkgs.python310Packages.adafruit-nrfutil
            minicom
          ];

          SDK_ROOT = "${pkgs.nrf5-sdk}/share/nRF5_SDK";
        };
      });
}

