#!/usr/bin/env bash

set -x
set -eo pipefail

mkdir -p mnt
sudo mount /dev/sda ./mnt
sudo tinygo build -target=nicenano -o ./mnt/firmware.uf2
sudo umount ./mnt
