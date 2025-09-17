.text	# 0x00000000
.globl _start
_start:
	la s0, b
	lw t0, -4(s0)
	lw t1, (s0)
loop:
	add t2, t1, t0
	mv t0, t1
	mv t1, t2
	addi s0, s0, 4
	sw t2, (s0)
	j loop
	
.data	# 0x00000100
a:	.word 0
b:	.word 1
