	.section .text
	.equ    UART_ADDR, 0x10000000
	.global _start

_start:
	la  sp,sp_top
	li  a0,5
	jal factorial
	jal printnum
	li  a0,10 # '\n'
	jal putchar
	j   halt

factorial:
	addi sp,sp,-16
	sw   a0,8(sp) # preserve a0
	sw   ra,0(sp)
	li   t0,2
	slt  t0,a0,t0 # t0 := (a0 < 2)
	beqz t0,fact_else

	li   a0,1 # return value
	addi sp,sp,16
	ret

fact_else:
	addi a0,a0,-1  # updated argument
	jal  factorial # factorial(n-1)
	mv   t0,a0     # save a0 at t0
	lw   ra,0(sp)
	lw   a0,8(sp)  # restore a0
	addi sp,sp,16
	mul  a0,a0,t0
	ret

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
