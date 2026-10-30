/* MicroBlaze boot stub: jump to Linux kernel loaded at 0x1C000000 */
	.text
	.globl _start
_start:
	/* kernel entry at 0x1C000000 (PS DDR via HP0, safe high CMA window) */
	brai	0x1C000000
	nop
