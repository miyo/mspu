	.section .text
	.equ UART_ADDR, 0x10000000 #UART
	.global _start

_start:
	la s0,message

loop:
	lb   a0,0(s0)
	addi s0,s0,1
	beqz a0,halt
	jal  putchar
	j    loop

putchar:
	li   t0,UART_ADDR
	sb   a0, 0(t0)
	ret

halt:
	j    halt

	.section .rodata

message:
	.ascii "Hello, RISC-V\n\0"
