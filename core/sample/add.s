	.section .text
	.equ STREAM_ADDR, 0x20003800 # 0x20000000+14KB
	.equ CONSTANT, 0x10000
	.global _start

_start:
	li   s0,STREAM_ADDR
	li   t1,CONSTANT
	addi s0,s0,8
	li   a0,14
loop:	
        lw   t0,0(s0)
	add  t0,t0,t1
        sw   t0,0(s0)
	addi a0,a0,-1
	beqz a0,halt
	addi s0,s0,4
	j    loop

halt:
	j    halt

	.section .rodata

message:
	.ascii "Hello, RISC-V\n\0"
