/* MicroBlaze boot stub: jump to Linux kernel loaded at 0x10000000 */
	.text
	.globl _start
_start:
	/* kernel entry at 0x10000000 (PS DDR via HP0) */
	brai	0x10000000
	nop
