OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
	. = 0x80000000;
	.text   : { *(.text)   }
	. = 0x20000000;
	.data : { *(.rodata) 
	          *(.data)
	          *(.bss)    }

	. = ALIGN(8);
	. = . + 0x0100; /* 256B */
	sp_top = .;
}

