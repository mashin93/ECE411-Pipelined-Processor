#  mp3-cp1.s version 3.0
.align 4
.section .text
.globl _start
_start:
	jal x1, JUMPONE
	nop
    nop
    nop
    nop
    nop
    nop
    nop
	addi x4, x4, 1

JUMPTWO:
	addi x2, x2, 1

HALT:	
    beq x0, x0, HALT
    nop
    nop
    nop
    nop
    nop
    nop
    nop

JUMPONE:
	addi x2, x2, 1
    nop
    nop
    nop
    nop
    nop
    nop
    nop
	jalr x1, x1, 14
	
.section .rodata
.balign 256
ONE:    .word 0x00000001
TWO:    .word 0x00000002
NEGTWO: .word 0xFFFFFFFE
TEMP1:  .word 0x00000001
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD

