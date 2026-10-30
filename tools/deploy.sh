#!/usr/bin/env bash
# Deploy MicroBlaze Linux to the Zynq-7010 board.
# Run AFTER the board has been rebooted (needs working sudo/devmem).
# Usage:  tools/deploy.sh [board_ip]
set -euo pipefail

BOARD="${1:-192.168.3.42}"
SSH="sshpass -p xilinx ssh -o StrictHostKeyChecking=no xilinx@$BOARD"
SCP="sshpass -p xilinx scp -o StrictHostKeyChecking=no"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
BUILDSRV="${BUILDSRV:-usbuild}"
BUILDSRV_DIR="${BUILDSRV_DIR:-/data/zynq7010-build}"

KERNEL_ADDR=0x1C000000      # 448 MB - high window, free after reboot
KERNEL_SEEK=$(( KERNEL_ADDR / 1024 / 1024 ))   # 448

# Fetch build artifacts from the remote build server if not present locally.
if [ ! -f "$HERE/sw/out/mb_kernel_flat.bin" ]; then
  echo "==> fetching kernel flat bin from $BUILDSRV"
  rsync -az "$BUILDSRV:$BUILDSRV_DIR/zynq7010-rv/sw/out/mb_kernel_flat.bin" \
            "$HERE/sw/out/" || { mkdir -p "$HERE/sw/out"; rsync -az \
            "$BUILDSRV:$BUILDSRV_DIR/zynq7010-rv/sw/out/mb_kernel_flat.bin" \
            "$HERE/sw/out/"; }
fi
if [ ! -f "$HERE/vivado/out/mb_soc_boot.bin" ]; then
  echo "==> fetching boot bitstream from $BUILDSRV"
  mkdir -p "$HERE/vivado/out"
  rsync -az "$BUILDSRV:$BUILDSRV_DIR/zynq7010-rv/vivado/out/mb_soc_boot.bin" \
            "$HERE/vivado/out/"
fi

echo "==> copying kernel + bitstream to board"
$SCP "$HERE/sw/out/mb_kernel_flat.bin"     "xilinx@$BOARD:/tmp/mb_kernel.bin"
$SCP "$HERE/vivado/out/mb_soc_boot.bin"    "xilinx@$BOARD:/tmp/mb_soc_boot.bin"

echo "==> loading kernel into DDR @ $KERNEL_ADDR"
$SSH "sudo dd if=/tmp/mb_kernel.bin of=/dev/mem bs=1M seek=$KERNEL_SEEK conv=fsync status=none && echo KERNEL_WRITTEN"

echo "==> programming PL"
$SSH "echo 0 | sudo tee /sys/class/fpga_manager/fpga0/flags >/dev/null; \
      sudo cp /tmp/mb_soc_boot.bin /lib/firmware/ ; \
      echo mb_soc_boot.bin | sudo tee /sys/class/fpga_manager/fpga0/firmware && echo FPGA_LOADED"

echo "==> reading MicroBlaze console on /dev/ttyPS1 (Ctrl-C to stop)"
$SSH "sudo stty -F /dev/ttyPS1 115200 raw -echo && sudo timeout 60 cat /dev/ttyPS1"
