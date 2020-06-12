#  mp3-cp1.s version 3.0
.align 4
.section .text
.globl _start
_start:
	la x2, TEMP1
	lw x1, %lo(BADD)(x0)
    nop
    nop
    nop
    nop
	nop
    nop
    nop
    nop
    nop
	sw x1, 0(x2)
	nop
    nop
    nop
    nop
	nop
    nop
    nop
    nop
    nop
	lw x3, 0(x2)
	

HALT:	
    beq x0, x0, HALT
    nop
    nop
    nop
    nop
    nop
    nop
    nop

	
.section .rodata
.balign 256
ONE:    .word 0x00000001
TWO:    .word 0x00000002
NEGTWO: .word 0xFFFFFFFE
TEMP1:  .word 0x00000001
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD

