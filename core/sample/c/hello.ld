OUTPUT_ARCH("riscv")
OUTPUT_FORMAT("elf32-littleriscv")
ENTRY(_start)

SECTIONS
{
	. = 0x80000000;

	.text : { startup.o(.text) 
	          *(.text)   }

	. = 0x20000000;
	.data   : { *(.data)   
	            *(.rodata) 
	            *(.bss)    }

	. = ALIGN(8);
	. = . + 0x0200; /* 512B */
	sp_top = .;
}

