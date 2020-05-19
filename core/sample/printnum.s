	.section .text
	.equ    UART_ADDR, 0x10000000
	.global _start

_start:
	la  sp,sp_top
	li  a0,345
	jal printnum
	li  a0,10 # '\n'
	jal putchar
	j   halt

printnum:
	addi sp,sp,-16
	sw   a0,8(sp)
	sw   ra,0(sp)
	li   t0,10
	div  t1,a0,t0 # t1 = a0/10
	bnez t1,printnum_else

	li   t0,48    # '0'
	add  a0,a0,t0 # '0' + a0
	jal  putchar

	lw   ra,0(sp)
	addi sp,sp,16
	ret

printnum_else:
	mv   a0,t1
	jal  printnum
	lw   a0,8(sp)
	li   t0,10
	rem  a0,a0,t0 # a0 = a0 % 10
	li   t0,48
	add  a0,a0,t0
	jal  putchar
	lw   ra,0(sp)
	addi sp,sp,16
	ret

putchar:
	li t0,UART_ADDR
	sb a0,0(t0)
	ret

halt:
	j halt
