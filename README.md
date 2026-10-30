# Zynq-7010 PL MicroBlaze SoC running Linux

MicroBlaze (with MMU) soft CPU in the PL of a Zynq-7010 (PYNQ-Z1 / S9 control
board), running a dedicated Linux kernel. The console is an AXI uartlite wired
back to the PS UART1 through EMIO, so the ARM side can act as the serial
console for the PL CPU.

## Layout

- `vivado/board_base.tcl` – block design: PS7 + MicroBlaze (MMU, AXI I/D, LMB)
  + LMB BRAM @0x0 + axi_uartlite @0x40600000 + interconnect to PS S_AXI_HP0.
- `vivado/build.tcl` – non-project build: synth / impl / bitstream.
- `sw/mb_soc.dts` – device tree for the MicroBlaze kernel.
- `sw/boot_stub.S` – reset stub programmed into LMB BRAM: jumps to the kernel
  at 0x10000000.
- `tools/build_remote.sh` – remote Vivado build driver.

## Memory map (MicroBlaze view)

| Region    | Address     | Size  | What                                   |
|-----------|-------------|-------|----------------------------------------|
| LMB BRAM  | 0x00000000  | 64KB  | reset vector + boot stub               |
| uartlite  | 0x40600000  | 64KB  | console                                |
| PS DDR    | 0x10000000  | 128MB | kernel image via S_AXI_HP0             |

## Boot flow

1. PS loads `simpleImage.zynq7010_mb` into DDR at 0x10000000 (`/dev/mem`).
2. PS downloads `mb_soc_boot.bin` (byte-swapped) via fpga_manager.
3. MicroBlaze exits reset at 0x0, runs the BRAM stub, jumps to the kernel.
4. Kernel prints to uartlite -> PS UART1 -> `/dev/ttyPS1` on the ARM side.

## Resources (xc7z010clg400-1)

- Slice LUTs 4420 / 17600 (25%)
- Slice regs 3861 / 35200 (11%)
- BRAM     24 / 60   (40%)
