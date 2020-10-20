	.section .text
	.equ UART_ADDR, 0x10000000 #UART
	.global _start

_start:
	la s0,message	/* s0 = 0x20000000 */

loop:
	li   s1,100	/* s1 = 100	*/
	li   s2,3	/* s2 = 3	*/
	slli s1,s1,2	/* s1 = s1 << 2 = 100 << 2 = 400	*/
	srl  s1,s1,s2	/* s1 = s1 >> s2 = 400 >> 3 = 50	*/
	addi s1,s1,1	/* s1 = s1 + 1 = 50 + 1 = 51	*/
	addi s2,s2,1	/* s2 = s2 + 1 = 3 + 1 = 4	*/
	sll  s1,s1,s2	/* s1 = s1 << s2 = 51 << 4 = 816	*/
	slli s1,s2,0	/* s1 = s2 << 0 = 4 << 0 = 4	*/
	li   s1,30	/* s1 = 30	*/
	li   s2,7	/* s2 = 7	*/
	div  s1,s1,s2	/* s1 = s1 / s2 = 30 / 7 = 4	*/
	li   s1,10	/* s1 = 10	*/
	li   s2,20	/* s2 = 20	*/
	mul  s1,s1,s2	/* s1 = s1 * s2 = 10 * 20 = 200	*/
	li   s1,30	/* s1 = 30	*/
	li   s2,7	/* s2 = 7	*/
	div  s3,s1,s2	/* s3 = s1 / s2 = 30 / 7 = 4	*/
	rem  s3,s1,s2	/* s3 = s1 % s2 = 30 / 7 = 2	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000000 + 1 = 0x20000001	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000001 + 1 = 0x20000002	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000002 + 1 = 0x20000003	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000003 + 1 = 0x20000004	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000004 + 1 = 0x20000005	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000005 + 1 = 0x20000006	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000006 + 1 = 0x20000007	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000007 + 1 = 0x20000008	*/
	addi s0,s0,1	/* s0 = s0 + 1 = 0x20000008 + 1 = 0x20000009	*/
	li   s1,30	/* s1 = 30	*/
	li   s2,7	/* s2 = 7	*/
	div  s3,s1,s2	/* s3 = s1 / s2 = 4	*/
	addi s3,s3,1	/* s3 = s3 + 1 = 4 + 1 = 5	*/

	j    halt

halt:
	j halt

	.section .rodata

message:
	.ascii "Hello, RISC-V\n\0"
