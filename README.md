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
  at 0x1C000000.
- `tools/build_remote.sh` – remote Vivado build driver.
- `tools/deploy.sh` – one-shot board deploy (kernel -> DDR, bin -> fpga_manager,
  console -> ttyPS1).

## Memory map (MicroBlaze view)

| Region    | Address     | Size  | What                                   |
|-----------|-------------|-------|----------------------------------------|
| LMB BRAM  | 0x00000000  | 64KB  | reset vector + boot stub               |
| uartlite  | 0x40600000  | 64KB  | console                                |
| PS DDR    | 0x1C000000  | 16MB  | kernel image via S_AXI_HP0 (CMA hi)   |

The DDR window sits at 448 MB, inside the 128 MB CMA region of the 512 MB
PS DDR. After a clean reboot that range is untouched by the PS kernel, so
writing the MicroBlaze kernel there does not corrupt the ARM side. (An
earlier 0x10000000 window overlapped live kernel memory and crashed the PS.)

## Boot flow

1. PS loads `simpleImage.zynq7010_mb` into DDR at 0x1C000000 (`/dev/mem`).
2. PS downloads `mb_soc_boot.bin` (byte-swapped) via fpga_manager.
3. MicroBlaze exits reset at 0x0, runs the BRAM stub, jumps to the kernel.
4. Kernel prints to uartlite -> PS UART1 -> `/dev/ttyPS1` on the ARM side.

The kernel is linked with `CONFIG_KERNEL_BASE_ADDR=0x1C000000`
(`CONFIG_KERNEL_START=0xC0000000` virtual), matching the AXI address segment.

## Resources (xc7z010clg400-1)

- Slice LUTs 4420 / 17600 (25%)
- Slice regs 3861 / 35200 (11%)
- BRAM     24 / 60   (40%)
