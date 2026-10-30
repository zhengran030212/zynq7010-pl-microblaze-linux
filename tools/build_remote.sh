#!/usr/bin/env bash
set -euo pipefail
server="${1:-usbuild}"
root="$(cd "$(dirname "$0")/.." && pwd)"
remote=/data/zynq7010-build/zynq7010-rv
image='aperloff/vivado-docker@sha256:857324f52eea066442f4a0355c5981db9060b28e6bc63765f6da1a2be35c998e'

rsync -az --exclude 'vivado/build/' --exclude 'vivado/out/' --exclude '__pycache__/' "$root/" "$server:$remote/"

ssh "$server" bash -s <<REMOTE
set -euo pipefail
docker image inspect $image >/dev/null 2>&1
docker run --rm --network none --cap-drop ALL --user 1000:1000 --cpus 4 --memory 20g \
  --entrypoint /bin/bash -v $remote:/work $image \
  -lc 'cd /work && /opt/Xilinx/Vivado/2019.1/bin/vivado -mode batch -source vivado/build.tcl' \
  > $remote/vivado.log 2>&1
REMOTE

mkdir -p "$root/vivado/out"
rsync -az "$server:$remote/vivado/out/" "$root/vivado/out/" 2>/dev/null || true
rsync -az "$server:$remote/vivado.log" "$root/vivado.log"
echo "done, log: $root/vivado.log"
