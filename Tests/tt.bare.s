# SPIM S20 MIPS simulator.
# A simple torture test for the bare SPIM simulator.
# Run with -notrap -delayed_branches -delayed_load flags (not -bare,
# as file uses pseudo ops).
#
# Copyright (c) 1990-2010, James R. Larus.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the James R. Larus nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#


# Define the exception handling code.  This must go first!
# Duplicate of standard trap handler.

	.data
	.globl __m1_
__m1_:	.asciiz "  Exception "
	.globl __m2_
__m2_:	.asciiz " occurred\n"
	.ktext 0x80000080
	mfc0 $26 $13	# Cause
	mfc0 $27 $14	# EPC
	addiu $v0 $0 4	# syscall 4 (print_str)
	la $a0 __m1_
	syscall
	addiu $v0 $0 1	# syscall 1 (print_int)
	addu $a0 $0 $26
	syscall
	addiu $v0 $0 4	# syscall 4 (print_str)
	la $a0 __m2_
	syscall
	mtc0 $0 $13		# Clear Cause register
	rfe			# Return from exception handler
	addiu $27 $27 4		# Return to next instruction
	jr $27
	nop

# Standard startup code.  Invoke the routine main with no arguments.

	.text
	.globl __start
__start: jal main
	nop
	addiu $v0 $0 10
	syscall			# syscall 10 (exit)


	.globl main
main:
	addu $20 $0 $31	# Save return PC

# Test delayed branches:

	.data
bc1fl_:	.asciiz "Testing BC1FL and BC1TL\n"
fp_s1:	.float 1.0
fp_s1p5:.float 1.5
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bc1fl_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.eq.s $f0 $f2
	bc1fl fail
	nop
	c.eq.s $f0 $f2
	bc1fl fail
	j fail

	c.eq.s $f0 $f4
	bc1tl fail
	nop
	c.eq.s $f0 $f4
	bc1tl fail
	j fail
	bc1fl l010
	j fail
	nop
l010:


# BC2FL BC2TL should be tested if CoProcessor 2 exists


	.data
beq_:	.asciiz "Testing BEQ and BEQL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 beq_
	syscall

	addiu $2 $0 0
	beq $0 $0 l020
	addiu $2 $0 1		# Delayed instruction
l020:	addiu $3 $0 1
	bne $2 $3 fail
	nop

	li $2 1
	li $3 1
	li $4 2
	li $5 0

	beq $2 $4 fail
	nop

	beq $2 $4 l021
	addu $5 $0 5		# Delay slot
l021:	bne $5 5 fail
	nop

	beql $2 $3 l022
	j fail
	nop

l022:	li $5 0
	beql $2 $3 l023
	addu $5 $0 5		# Delay slot
l023:	bne $5 5 fail
	nop


# BGEZAL and BGEZALL should be tested


	.data
bgez_:	.asciiz "Testing BGEZ and BGEZL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bgez_
	syscall

	addiu $2 $0 0
	bgez $0 l030
	addiu $2 $0 1		# Delayed instruction
l030:	addiu $3 $0 1
	bne $2 $3 fail
	nop

	li $2 1
	li $3 -1
	li $4 2
	li $5 0

	bgez $3 fail
	nop

	bgez $2 l031
	addu $5 $0 5		# Delay slot
l031:	bne $5 5 fail
	nop

	bgezl $2 l032
	j fail
	nop

l032:	li $5 0
	bgezl $2 l033
	addu $5 $0 5		# Delay slot
l033:	bne $5 5 fail
	nop


	.data
bgtz_:	.asciiz "Testing BGTZ and BGTZL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bgtz_
	syscall

	addiu $2 $0 0
	bgtz $0 l040
	addiu $2 $0 1		# Delayed instruction
	addiu $2 $0 2
l040:	addiu $3 $0 2
	bne $2 $3 fail
	nop

	li $2 1
	li $3 -1
	li $4 2
	li $5 0

	bgtz $3 fail
	nop

	bgtz $2 l041
	addu $5 $0 5		# Delay slot
l041:	bne $5 5 fail
	nop

	bgtzl $2 l042
	j fail
	nop

l042:	li $5 0
	bgtzl $2 l043
	addu $5 $0 5		# Delay slot
l043:	bne $5 5 fail
	nop


	.data
blez_:	.asciiz "Testing BLEZ and BLEZL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 blez_
	syscall

	addiu $2 $0 0
	blez $0 l050
	addiu $2 $0 1		# Delayed instruction
l050:	addiu $3 $0 1
	bne $2 $3 fail
	nop

	li $2 1
	li $3 -1
	li $4 2
	li $5 0

	blez $2 fail
	nop

	blez $3 l051
	addu $5 $0 5		# Delay slot
l051:	bne $5 5 fail
	nop

	blezl $3 l052
	j fail
	nop

l052:	li $5 0
	blezl $3 l053
	addu $5 $0 5		# Delay slot
l053:	bne $5 5 fail
	nop


	.data
bltz_:	.asciiz "Testing BLTZ and BLTZL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bltz_
	syscall

	addiu $2 $0 0
	bltz $0 l060
	addiu $2 $0 1		# Delayed instruction
	addiu $2 $0 2
l060:	addiu $3 $0 2
	bne $2 $3 fail
	nop

	li $2 1
	li $3 -1
	li $4 2
	li $5 0

	bltz $2 fail
	nop

	bltz $3 l061
	addu $5 $0 5		# Delay slot
l061:	bne $5 5 fail
	nop

	bltzl $3 l062
	j fail
	nop

l062:	li $5 0
	bltzl $3 l063
	addu $5 $0 5		# Delay slot
l063:	bne $5 5 fail
	nop


# BLTZAL and BLTZALL should be tested


	.data
bne_:	.asciiz "Testing BNE and BNEL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bne_
	syscall

	addiu $2 $0 0
	bne $0 $0 l070
	addiu $2 $0 1		# Delayed instruction
l070:	addiu $3 $0 1
	bne $2 $3 fail
	nop

	li $2 1
	li $3 1
	li $4 2
	li $5 0

	bne $2 $3 fail
	nop

	bne $2 $4 l071
	addu $5 $0 5		# Delay slot
l071:	bne $5 5 fail
	nop

	bnel $2 $3 l072
	j fail
	nop

l072:	li $5 0
	bnel $2 $3 l073
	addu $5 $0 5		# Delay slot
l073:	bne $5 0 fail
	nop


# Test delayed loads:

	.data
	.globl d
d:	.word 101
ld_:	.asciiz "Testing LD\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ld_
	syscall

	addiu $3 $0 0
	la $4 d
	lw $3 d
	addu $3 $0 5		# Delayed instruction
	bne $3 101 fail
	nop


# Done !!!
	.data
	.globl sm
sm:	.asciiz "\nPassed all tests\n"
	.text
	addiu $v0 $0 4	# syscall 4 (print_str)
	la $a0 sm
	syscall
	addu $31 $0 $20	# Return PC
	jr $31			# Return from main
	nop


	.data
	.globl fm
fm:	.asciiz "Failed test\n"
	.text
fail:	addiu $v0 $0 4	# syscall 4 (print_str)
	la $a0 fm
	syscall
	addiu $v0 $0 10	# syscall 10 (exit)
	syscall
