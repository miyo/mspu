	.section .text
	.equ UART_ADDR, 0x10000000 #UART
	.global _start

_start:
	la s0,message

loop:
	addi s0,s0,1
	addi s0,s0,1
	addi s0,s0,1
	addi s0,s0,1
	addi s0,s0,1
	addi s0,s0,1
	addi s0,s0,1
	addi s0,s0,1
	addi s0,s0,1
	li   s1,10
	li   s2,20
	mul  s1,s1,s2

	j    halt

halt:
	j halt

	.section .rodata

message:
	.ascii "Hello, RISC-V\n\0"
