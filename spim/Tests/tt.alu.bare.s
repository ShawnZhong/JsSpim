# SPIM S20 MIPS simulator.
# A torture test for the ALU instructions in the bare SPIM simulator.
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


# Adapted by Anne Rogers <amr@blueline.Princeton.EDU> from tt.le.s.
# Run -bare -notrap.

# IMPORTANT!!!
# This file only works on little-endian machines.
#

# Test ALU instructions.

# WARNING: This code is not relocatable.  DO NOT add instructions without
# changing test code for JAL, JALR, BGEZAL, BLTZAL.  Add new "data" statements
# only at after "Passed all tests\n".


	.data
saved_ret_pc:	.word 0		# Holds PC to return from main
sm:      .asciiz "Failed  "
	.text
# Standard startup code.  Invoke the routine main with no arguments.
	.globl __start
__start: jal main
	addu $0 $0 $0		# Nop
	addiu $2 $0 10
	syscall			# syscall 10 (exit)
	addu $0 $0 $0		# Nop
	addu $0 $0 $0		# Nop
	addu $0 $0 $0		# Nop
	addu $0 $0 $0		# Nop

	.globl main
main:
	lui $4 0x1000
	sw $31 0($4)

#
# Try modifying R0
#
	addi $0 $0 1

#
# Now, test each instruction
#

	.data
add_:	.asciiz "Testing ADD\n"
	.text
	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 add_
	lui $a0, 0x1000
	ori $a0 $a0 0xd
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	add $4 $0 $0
	bne $4 $0 fail
	addu $0 $0 $0		# Nop
	add $4 $0 $2
	bne $4 $2 fail
	addu $0 $0 $0		# Nop
	add $4 $4 $3
	bne $4 $0 fail
	addu $0 $0 $0		# Nop

	.data
addi_:	.asciiz "Testing ADDI\n"
	.text
	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 addi_
	lui $a0, 0x1000
	ori $a0 $a0 0x1a
	syscall

	addi $2 $0 1

	addi $4 $0 0
	bne $4 $0 fail
	addu $0 $0 $0		# Nop
	addi $4 $0 1
	bne $4 $2 fail
	addu $0 $0 $0		# Nop
	addi $4 $4 -1
	bne $4 $0 fail


	.data
addiu_:	.asciiz "Testing ADDIU\n"
	.text
	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 addiu_
	lui $a0, 0x1000
	ori $a0 $a0 0x28
	syscall

	addi $2 $0 1
	addiu $4 $0 0
	bne $4 $0 fail
	addu $0 $0 $0		# Nop
	addiu $4 $0 1
	bne $4 $2 fail
	addu $0 $0 $0		# Nop
	addiu $4 $4 -1
	bne $4 $0 fail
	addu $0 $0 $0		# Nop

	lui $2 0x3fff
	ori $2 $2 0xffff
	addiu $2 $2 101


	.data
addu_:	.asciiz "Testing ADDU\n"
	.text
	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 addu_
	lui $a0, 0x1000
	ori $a0 $a0 0x37
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	addu $4 $0 $0
	bne $4 $0 fail
	addu $0 $0 $0		# Nop
	addu $4 $0 $2
	bne $4 $2  fail
	addu $0 $0 $0		# Nop
	addu $4 $4 $3
	bne $4 $0 fail
	addu $0 $0 $0		# Nop


	lui $2 0x3fff
	ori $2 $2 0xffff
	addu $2 $2 $2


	.data
and_:	.asciiz "Testing AND\n"
	.text
	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 and_
	lui $a0, 0x1000
	ori $a0 $a0 0x37
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	and $4 $0 $0
	bne $4 $0 fail
	addu $0 $0 $0		# Nop
	and $4 $2 $2
	beq $4 $0 fail
	addu $0 $0 $0		# Nop
	and $4 $2 $3
	bne $4 $2 fail


	.data
andi_:	.asciiz "Testing ANDI\n"
	.text
	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 andi_
	lui $a0, 0x1000
	ori $a0 $a0 0x52
	syscall

	addi $2 $0 1
	addi $3 $0 -1
	addi $5 $0 -1

	andi $4 $0 0
	bne $4 $0 fail
	addu $0 $0 $0		# Nop
	and $4 $2 1
	beq $4 $0 fail
	addu $0 $0 $0		# Nop
	and $4 $2 $5
	bne $4 $2 fail
	addu $0 $0 $0		# Nop
	and $4 $3 $5
	bne $4 $3 fail
	addu $0 $0 $0		# Nop


	.data
beq_:	.asciiz "Testing BEQ\n"
	.text
	add $v0 $0 4	# syscall 4 (print_str)
#	la $a0 beq_
	lui $a0, 0x1000
	ori $a0 $a0 0x60
	syscall

	add $2 $0 -1
	add $3 $0 1

	beq $0 $0 l1
#	j fail
   	addu $0 $0 $0		# Nop
l1:	beq $2 $2 l2
#	j fail
   	addu $0 $0 $0		# Nop
l2:	beq $3 $2 fail
   	addu $0 $0 $0		# Nop

	addi $2 $0 3
l2_1:	sub $2 $2 $3
	bne $2 $0 l2_1
	addu $0 $0 $0		# Nop


	.data
bgez_:	.asciiz "Testing BGEZ\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 bgez_
	lui $a0, 0x1000
	ori $a0 $a0 0x6d

	syscall

	addi $2 $0 -1
	addi $3 $0 1

	bgez $0 l3
	addu $0 $0 $0           # Nop
	j fail
l3:	bgez $3 l4
	addu $0 $0 $0           # Nop
	j fail
l4:	bgez $2 fail
	addu $0 $0 $0           # Nop

	.data
bgtz_:	.asciiz "Testing BGTZ\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 bgtz_
	lui $a0, 0x1000
	ori $a0 $a0 0x7b
	syscall

	addi $2 $0 -1
	addi $3 $0 1

	bgtz $0 fail
	addu $0 $0 $0		# Nop
l7:	bgtz $3 l8
	addu $0 $0 $0		# Nop
	j fail
l8:	bgtz $2 fail
	addu $0 $0 $0		# Nop

	.data
blez_:	.asciiz "Testing BLEZ\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 blez_
	lui $a0, 0x1000
	ori $a0 $a0 0x89
	syscall

	addi $2 $0 -1
	addi $3 $0 1

	blez $0 l9
	addu $0 $0 $0		# Nop
	j fail
l9:	blez $2 l10
	addu $0 $0 $0		# Nop
	j fail
l10:	blez $3 fail
	addu $0 $0 $0		# Nop

	.data
bltz_:	.asciiz "Testing BLTZ\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 bltz_
	lui $a0, 0x1000
	ori $a0 $a0 0x97

	syscall

	addi $2 $0 -1
	addi $3 $0 1

	bltz $0 fail
	addu $0 $0 $0		# Nop
l11:	bltz $2 l12
	addu $0 $0 $0		# Nop
	j fail
l12:	bltz $3 fail
	addu $0 $0 $0		# Nop

	.data
bne_:	.asciiz "Testing BNE\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 bne_
	lui $a0, 0x1000
	ori $a0 $a0 0xa5
	syscall

	addi $2 $0 -1
	addi $3 $0 1

	bne $0 $0 fail
	addu $0 $0 $0		# Nop
	bne $2 $2 fail
	addu $0 $0 $0		# Nop
	bne $3 $2 l16
	addu $0 $0 $0		# Nop
l16:
	addu $0 $0 $0		# Nop

	.data
j_:	.asciiz "Testing J\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 j_
	lui $a0, 0x1000
	ori $a0 $a0 0xb2
	syscall

	j l17
	j fail
l17:  	addu $0 $0 $0		# Nop


	.data
lb_:	.asciiz "Testing LB\n"
# lb2_:	.asciiz "Expect a address error exceptions:\n  "
lbd_:	.byte 1, -1, 0, 128
lbd1_:	.word 0x76543210, 0xfedcba98
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lb_
	lui $a0, 0x1000
	ori $a0 $a0 0xbd

	syscall

#	la $2 lbd_
	lui $2, 0x1000
	ori $2 $2 0xc9
	lb $3 0($2)
  	addu $4 $0 1
	bne $3 $4 fail
	lb $3 1($2)
	addi $4 $0 -1
	bne $3 $4 fail
	lb $3 2($2)
  	addu $0 $0 $0		# Nop
	bne $3 $0 fail
	lb $3 3($2)
	lui $4 0xffff
	ori $4 0xff80
	bne $3 $4 fail

#	la $t0 lbd1_
	lui $t0, 0x1000
	ori $t0 $t0 0xd0
	lb $t1 0($t0)
	addi $4 $0 0x10
	bne $t1 $4 fail
	lb $t1 1($t0)
	addi $4 $0 0x32
	bne $t1 $4 fail
	lb $t1 2($t0)
	addi $4 $0 0x54
	bne $t1 $4 fail
	lb $t1 3($t0)
	addi $4 $0 0x76
	bne $t1 $4 fail
	lb $t1 4($t0)
	lui $4 0xffff
	addi $4 $0 0xff98
	bne $t1 $4 fail
	lb $t1 5($t0)
	lui $4 0xffff
	addi $4 $0 0xffba
	bne $t1 $4 fail
	lb $t1 6($t0)
	lui $4 0xffff
	addi $4 $0 0xffdc
	bne $t1 $4 fail
	lb $t1 7($t0)
	lui $4 0xffff
	addi $4 $0 0xfffe
	bne $t1 $4 fail

#	li $v0 4	# syscall 4 (print_str)
#	la $a0 lb2_
#	syscall
#
#	lb $3 1000000($sp)


	.data
lbu_:	.asciiz "Testing LBU\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lbu_
	lui $a0, 0x1000
	ori $a0 $a0 0xd8
	syscall

#	la $2 lbd_
	lui $2, 0x1000
	ori $2 $2 0xc9

	lbu $3 0($2)
	addi $4 $0 1
	bne $3 $4 fail
	lbu $3 1($2)
	addi $4 $0 0xff
	bne $3 $4 fail
	lbu $3 2($2)
        addu $0 $0 $0         # Nop
	bne $3 $0 fail
	lbu $3 3($2)
	addu $4 $0 128
	bne $3 $4 fail

#	la $t0 lbd1_
	lui $t0, 0x1000
	ori $t0 $t0 0xd0

	lbu $t1 0($t0)
	addi $4 $0 0x10
	bne $t1 $4 fail
	lbu $t1 1($t0)
	addi $4 $0 0x32
	bne $t1 $4 fail
	lbu $t1 2($t0)
	addi $4 $0 0x54
	bne $t1 $4 fail
	lbu $t1 3($t0)
	addi $4 $0 0x76
	bne $t1 $4 fail
	lbu $t1 4($t0)
	addi $4 $0 0x98
	bne $t1 $4 fail
	lbu $t1 5($t0)
	addi $4 $0 0xba
	bne $t1 $4 fail
	lbu $t1 6($t0)
	addi $4 $0 0xdc
	bne $t1 $4 fail
	lbu $t1 7($t0)
	addi $4 $0 0xfe
	bne $t1 $4 fail
	addu $0 $0 $0          # Nop

#       Causes an exception -- do later.
#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lb2_
#	syscall
#
#	lbu $3 1000000($sp)


	.data
lh_:	.asciiz "Testing LH\n"
#lh2_:	.asciiz "Expect two address error exceptions:\n	"
lhd_:	.half 1, -1, 0, 0x8000
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lh_
	lui $a0, 0x1000
	ori $a0 $a0 0xe5
	syscall

#	la $2 lhd_
	lui $2, 0x1000
	ori $2 $2 0xf2
	lh $3 0($2)
	addi $4 $0 1
	bne $3 $4 fail
	lh $3 2($2)
	addi $4 $0 -1
	bne $3 $4 fail
	lh $3 4($2)
	addi $4 $0 0
	bne $3 $4 fail
	lh $3 6($2)
	lui $4 0xffff
	ori $4 $4 0x8000
	bne $3 $4 fail
	addu $0 $0 $0     # Nop

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lh2_
#	syscall
#
#	lh $3 1000000($sp)
#	lh $3 1000001($sp)

	.data
lhu_:	.asciiz "Testing LHU\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lhu_
	lui $a0, 0x1000
	ori $a0 $a0 0xfa
	syscall

#	la $2 lhd_
	lui $2, 0x1000
	ori $2 $2 0xf2
	lhu $3 0($2)
	addi $4 $0 1
	bne $3 $4 fail
	lhu $3 2($2)
	ori $4 $0 0xffff
	bne $3 $4 fail
	lhu $3 4($2)
	addi $4 $0 0
	bne $3 $4 fail
	lhu $3 6($2)
	ori $4 $0 0x8000
	bne $3 $4 fail
	addu $0 $0 $0   #Nop

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lh2_
#	syscall
#
#	lhu $3 1000000($sp)
#	lhu $3 1000001($sp)


	.data
lui_:	.asciiz "Testing LUI\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lui_
	lui $a0, 0x1000
	ori $a0 $a0 0x107
	syscall

	lui $2 0
	bne $2 $0 fail
	lui $2 1
	srl $2 $2 16
	addiu $2 $2 -1	# Don't do compare directly since it uses LUI
	bne $2 $0 fail
	lui $2 1
	andi $2 $2 0xffff
	bne $2 $0 fail
	lui $2 -1
	srl $2 $2 16
	addiu $2 $2 1
	andi $2 $2 0xffff
	bne $2 $0 fail
	addu $0 $0 $0   #Nop

	.data
lw_:	.asciiz "Testing LW\n"
lwd_:	.word 1, -1, 0, 0x8000000
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lw_
	lui $a0, 0x1000
	ori $a0 $a0 0x114
	syscall

#	la $2 lwd_
	lui $2, 0x1000
	ori $2 $2 0x120
	lw $3 0($2)
	addi $4 $0 1
	bne $3 $4 fail
	lw $3 4($2)
	addi $4 $0 -1
	bne $3 $4 fail
	lw $3 8($2)
	addi $4 $0 0
	bne $3 $4 fail
	lw $3 12($2)
	lui $4 0x800
	ori $4 $4 0x0000
	bne $3 $4 fail

	add $2 $2 12
	lw $3 -12($2)
	addi $4 $0 1
	bne $3 $4 fail
	lw $3 -8($2)
	addi $4 $0 -1
	bne $3 $4 fail
	lw $3 -4($2)
	addi $4 $0 0
	bne $3 $4 fail
	lw $3 0($2)
	lui $4 0x800
	ori $4 $4 0x0000
	bne $3 $4 fail
	addu $0 $0 $0   #Nop

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lh2_
#	syscall
#
#	lw $3 1000000($sp)
#	lw $3 1000001($sp)

	.data
lwl_:	.asciiz "Testing LWL\n"
	.align 2
lwld_:	.byte 0 1 2 3 4 5 6 7
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lwl_
	lui $a0, 0x1000
	ori $a0 $a0 0x130
	syscall

#	la $2 lwld_
	lui $2, 0x1000
	ori $2 $2 0x140
	addu $3 $0 $0              # Move $3 $0
	lwl $3 0($2)
	addi $4 $0 0
	bne $3 $4 fail
	addu $3 $0 $0              # Move $3 $0
	lwl $3 1($2)
	lui $4 0x0100
	ori $4 $4 0x0000
	bne $3 $4 fail
	addi $3 $0 5
	lwl $3 1($2)
	lui $4 0x0100
	ori $4 $4 0x0005
	bne $3 $4 fail
	addu $3 $0 $0              # Move $3 $0
	lwl $3 2($2)
	lui $4 0x0201
	ori $4 $4 0x0000
	bne $3 $4 fail
	addi $3 $0 5
	lwl $3 2($2)
	lui $4 0x0201
	ori $4 $4 0x0005
	bne $3 $4 fail
	addu $3 $0 $0              # Move $3 $0
	lwl $3 3($2)
	lui $4 0x0302
	ori $4 $4 0x0100
	bne $3 $4 fail
	addi $3 $0 5
	lwl $3 3($2)
	lui $4 0x0302
	ori $4 $4 0x0100
	bne $3 $4 fail
	addu $0 $0 $0    # Nop

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lh2_
#	syscall
#
#	lwl $3 1000000($sp)
#	lwl $3 1000001($sp)



	.data
lwr_:	.asciiz "Testing LWR\n"
	.align 2
lwrd_:	.byte 0 1 2 3 4 5 6 7
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lwr_
	lui $a0, 0x1000
	ori $a0 $a0 0x148
	syscall

#	la $2 lwrd_
	lui $2, 0x1000
	ori $2 $2 0x158

	lui $3 0x0000
	ori $3 $3 0x0500
	lwr $3 0($2)
	lui $4 0x0302
	ori $4 $4 0x0100
	bne $3 $4 fail
	addu $3 $0 $0              # Move $3 $0
	lwr $3 1($2)
	lui $4 0x0003
	ori $4 $4 0x0201
	bne $3 $4 fail
	lui $3 0x5000
	ori $3 $3 0x0000
	lwr $3 1($2)
	lui $4 0x5003
	ori $4 $4 0x0201
	bne $3 $4 fail
	addu $3 $0 $0              # Move $3 $0
	lwr $3 2($2)
	ori $4 $0 0x0302
	bne $3 $4 fail
	lui $3 0x5000
	ori $3 $3 0x0000
	lwr $3 2($2)
	lui $4 0x5000
	ori $4 $4 0x0302
	bne $3 $4 fail
	addu $0 $0 $0            # Nop

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lh2_
#	syscall
#
#	lwr $3 1000000($sp)
#	lwr $3 1000001($sp)

	.data
nor_:	.asciiz "Testing NOR\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 nor_
	lui $a0, 0x1000
	ori $a0 $a0 0x160
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	nor $4 $0 $0
	addi $5 $0 -1
	bne $4 $5 fail
	nor $4 $2 $2
	lui $5 0xffff
	ori $5 $5 0xfffe
	bne $4 $5 fail
	nor $4 $2 $3
	bne $4 $0 fail
	addu $0 $0 $0             #Nop

	.data
or_:	.asciiz "Testing OR\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 or_
	lui $a0, 0x1000
	ori $a0 $a0 0x16d
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	or $4 $0 $0
	bne $4 $0 fail
	or $4 $2 $2
	addi $5 $0 1
	bne $4 $5 fail
	or $4 $2 $3
	addi $5 $0 -1
	bne $4 $5  fail
	addu $0 $0 $0   #Nop


	.data
ori_:	.asciiz "Testing ORI\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 ori_
	lui $a0, 0x1000
	ori $a0 $a0 0x179
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	ori $4 $0 0
	bne $4 $0 fail
	ori $4 $2 1
	addi $5 $0 1
	bne $4 $5 fail
	ori $4 $3 -1
	lui $5 0xffff
	ori $5 $5 0xffff
	bne $4 $5 fail
	addu $0 $0 $0   #Nop

	.data
sb_:	.asciiz "Testing SB\n"
#sb2_:	.asciiz "Expect a address error exceptions:\n  "
	.align 2
sbd_:	.byte 0, 0, 0, 0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sb_
	lui $a0, 0x1000
	ori $a0 $a0 0x186
	syscall

	addi $3 $0, 1
#	la $2 sbd_
	lui $2, 0x1000
	ori $2 $2 0x194
	sb $3 0($2)
	lw $4 0($2)
	ori $5 $0 0x1
	bne $4 $5 fail
	addi $3 $0 2
	sb $3 1($2)
	lw $4 0($2)
	ori $5 $0 0x201
	bne $4 $5 fail
	addi $3 $0 3
	sb $3 2($2)
	lw $4 0($2)
	lui $5 0x3
	ori $5 $5 0x0201
	bne $4 $5 fail
	addi $3 $0 4
	sb $3 3($2)
	lw $4 0($2)
	lui $5 0x0403
	ori $5 $5 0x0201
	bne $4 $5 fail
	addu $0 $0 $0   #Nop

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sb2_
#	syscall
#
#	sb $3 1000000($sp)


# RFE tested previously

	.data
sh_:	.asciiz "Testing SH\n"
#sh2_:	.asciiz "Expect two address error exceptions:\n	"
	.align 2
shd_:	.byte 0, 0, 0, 0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sh_
	lui $a0, 0x1000
	ori $a0 $a0 0x198
	syscall

	addi $3 $0, 1
#	la $2 shd_
	lui $2, 0x1000
	ori $2 $2 0x1a4

	sh $3 0($2)
	lw $4 0($2)
	ori $5 $0 0x1
	bne $4 $5 fail
	addi $3 $0 2
	sh $3 2($2)
	lw $4 0($2)
	lui $5 0x2
	ori $5 $5 0x0001
	bne $4 $5 fail
	addu $0 $0 $0   #Nop

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sh2_
#	syscall
#
#	sh $3 1000000($sp)
#	sh $3 1000001($sp)

	.data
sll_:	.asciiz "Testing SLL\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sll_
	lui $a0, 0x1000
	ori $a0 $a0 0x1a8
	syscall

	addi $2 $0 1

	sll $3 $2 0
	ori $4 $0 1
	bne $3 $4 fail
	sll $3 $2 1
	ori $4 $0 2
	bne $3 $4 fail
	sll $3 $2 16
	lui $4 0x1
	ori $4 $4 0x0000
	bne $3 $4 fail
	sll $3 $2 32
	ori $4 $0 1
	bne $3 $4 fail
	addu $0 $0 $0           # Nop

	.data
sllv_:	.asciiz "Testing SLLV\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sllv_
	lui $a0, 0x1000
	ori $a0 $a0 0x1b5
	syscall

	addi $2 $0 1
	addi $4 $0 0
	sllv $3 $2 $4
	ori $5 $0 1
	bne $3 $5 fail
	addi $4 $0 1
	sllv $3 $2 $4
	ori $5 $0 2
	bne $3 $5 fail
	addi $4 $0 16
	sllv $3 $2 $4
	lui $5 0x1
	ori $5 $5 0x0000
	bne $3 $5 fail
	addi $4 $0 32
	sllv $3 $2 $4
	ori $5 $0 1
	bne $3 $5 fail
	addu $0 $0 $0            # Nop

	.data
slt_:	.asciiz "Testing SLT\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 slt_
	lui $a0, 0x1000
	ori $a0 $a0 0x1c3
	syscall

	ori $5 $0 1

	slt $3 $0 $0
	bne $3 $0 fail
	addi $2 $0 1
	slt $3 $2 $0
	bne $3 $0 fail
	slt $3 $0 $2
	bne $3 $5 fail
	addi $2 $0 -1
	slt $3 $2 $0
	bne $3 $5 fail
	slt $3 $0 $2
	bne $3 $0 fail
	addi $2 $0 -1
	addi $4 $0 1
	slt $3 $2 $4
	bne $3 $5 fail
	addu $0 $0 $0         # Nop

	.data
slti_:	.asciiz "Testing SLTI\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 slti_
	lui $a0, 0x1000
	ori $a0 $a0 0x1d0
	syscall

	ori $5 $0 1

	slti $3 $0 0
	bne $3 $0 fail
	addi $2 $0 1
	slti $3 $2 0
	bne $3 $0 fail
	slti $3 $0 1
	bne $3 $5 fail
	addi $2 $0 -1
	slti $3 $2 0
	bne $3 $5 fail
	slti $3 $0 -1
	bne $3 $0 fail
	addi $2 $0 -1
	addi $4 $0 1
	slti $3 $2 1
	bne $3 $5 fail
	slti $3 $4 -1
	bne $3 $0 fail
	addu $0 $0 $0           # Nop


	.data
sltiu_:	.asciiz "Testing SLTIU\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sltiu_
	lui $a0, 0x1000
	ori $a0 $a0 0x1de
	syscall

	ori $5 $0 1

	sltiu $3 $0 0
	bne $3 $0 fail
	addi $2 $0 1
	sltiu $3 $2 0
	bne $3 $0 fail
	sltiu $3 $0 1
	bne $3 $5 fail
	addi $2 $0 -1
	sltiu $3 $2 0
	bne $3 $0 fail
	sltiu $3 $0 -1
	bne $3 $5 fail
	addi $2 $0 -1
	addi $4 $0 1
	sltiu $3 $2 1
	bne $3 $0 fail
	sltiu $3 $4 -1
	bne $3 $5 fail
	addu $0 $0 $0        # Nop


	.data
sltu_:	.asciiz "Testing SLTU\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sltu_
	lui $a0, 0x1000
	ori $a0 $a0 0x1ed
	syscall

	ori $5 $0 1

	sltu $3 $0 $0
	bne $3 $0 fail
	addi $2 $0 1
	sltu $3 $2 $0
	bne $3 $0 fail
	sltu $3 $0 $2
	bne $3 $5 fail
	addi $2 $0 -1
	sltu $3 $2 $0
	bne $3 $0 fail
	sltu $3 $0 $2
	bne $3 $5 fail
	addi $2 $0 -1
	addi $4 $0 1
	sltu $3 $2 $4
	bne $3 $0 fail
	addu $0 $0 $0            # Nop

	.data
sra_:	.asciiz "Testing SRA\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sra_
	lui $a0, 0x1000
	ori $a0 $a0 0x1fb
	syscall

	addi $2 $0 1
	sra $3 $2 0
	ori $5 $0 1
	bne $3 $5 fail
	sra $3 $2 1
	bne $3 $0 fail
	addi $2 $0 0x1000
	sra $3 $2 4
	ori $5 $0 0x100
	bne $3 $5 fail
	lui $5 0x8000
	ori $5 $5 0x0000
	add $2 $0 $5
	sra $3 $2 4
	lui $5 0xf800
	ori $5 $5 0x0000
	bne $3 $5 fail
	addu $0 $0 $0                # Nop

	.data
srav_:	.asciiz "Testing SRAV\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 srav_
	lui $a0, 0x1000
	ori $a0 $a0 0x208
	syscall

	addi $2 $0 1
	addi $4 $0 0
	srav $3 $2 $4
	ori $5 $0 1
	bne $3 $5 fail
	addi $4 $0 1
	srav $3 $2 $4
	bne $3 $0 fail
	addi $2 $0 0x1000
	addi $4 $0 4
	srav $3 $2 $4
	ori $5 $0 0x100
	bne $3 $5 fail
	lui $5 0x8000
	ori $5 $5 0x0000
	add $2 $0 $5
	addi $4 $0 4
	srav $3 $2 $4
	lui $5 0xf800
	ori $5 $5 0x0000
	bne $3 $5 fail
	addu $0 $0 $0           # Nop



	.data
srl_:	.asciiz "Testing SRL\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 srl_
	lui $a0, 0x1000
	ori $a0 $a0 0x216
	syscall

	addi $2 $0 1
	srl $3 $2 0
	ori $5 $0 1
	bne $3 $5 fail
	srl $3 $2 1
	bne $3 $0 fail
	addi $2 $0 0x1000
	srl $3 $2 4
	ori $5 $0 0x100
	bne $3 $5 fail
	lui $5 0x8000
	ori $5 $0 0x0000
	add $2 $0 $5
	srl $3 $2 4
	lui $5 0x0800
	ori $5 $0 0x0000
	bne $3 $5 fail
	addu $0 $0 $0           #Nop


	.data
srlv_:	.asciiz "Testing SRLV\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 srlv_
	lui $a0, 0x1000
	ori $a0 $a0 0x223
	syscall

	addi $2 $0 1
	addi $4 $0 0
	srlv $3 $2 $4
	ori $5 $0 1
	bne $3 $5 fail
	addi $4 $0 1
	srlv $3 $2 $4
	bne $3 $0 fail
	addi $2 $0 0x1000
	addi $4 $0 4
	srlv $3 $2 $4
	ori $5 $0 0x100
	bne $3 $5 fail
	lui $5 0x8000
	ori $5 $5 0x0000
	add $2 $0 $5
	addi $4 $0 4
	srlv $3 $2 $4
	lui $5 0x0800
	ori $5 $5 0x0000
	bne $3 $5 fail
	addu $0 $0 $0                     # Nop


	.data
sub_:	.asciiz "Testing SUB\n"
# sub1_:	.asciiz "Expect an overflow exceptions:\n  "
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sub_
	lui $a0, 0x1000
	ori $a0 $a0 0x231
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	sub $4, $0, $0
	bne $4 $0 fail
	sub $4, $0, $2
	addi $5 $0 -1
	bne $4 $5 fail
	sub $4, $2, $0
	ori $5 $0 1
	bne $4, $5 fail
	sub $4, $2, $3
	ori $5 $0 2
	bne $4, $5 fail
	sub $4, $3, $2
	addi $5 $0 -2
	bne $4, $5 fail
	addu $0 $0 $0                   # Nop

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sub1_
#	syscall
#	addi $2 $0 0x80000000
#	addi $3 $0 1
#	sub $4, $3, $2

	.data
subu_:	.asciiz "Testing SUBU\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 subu_
	lui $a0, 0x1000
	ori $a0 $a0 0x23e
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	subu $4, $0, $0
	bne $4 $0 fail
	subu $4, $0, $2
	addi $5 $0 -1
	bne $4 $5 fail
	subu $4, $2, $0
	addi $5 $0 1
	bne $4, $5 fail
	subu $4, $2, $3
	addi $5 $0 2
	bne $4, $5 fail
	subu $4, $3, $2
	addi $5 $0 -2
	bne $4, $5 fail

	lui $5 0x8000
	ori $5 $5 0x0000
	add $2 $0 $5
	addi $3 $0 1
	subu $4, $3, $2

	.data
sw_:	.asciiz "Testing SW\n"
#sw2_:	.asciiz "Expect two address error exceptions:\n	"
	.align 2
swd_:	.byte 0, 0, 0, 0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sw_
	lui $a0, 0x1000
	ori $a0 $a0 0x24c
	syscall

#	addi $3 $0, 0x7f7f7f7f
	lui $3 0x7f7f
	ori $3 $3 0x7f7f
#	la $2 swd_
	lui $2, 0x1000
	ori $2 $2 0x258
	sw $3 0($2)
	lw $4 0($2)
	lui $5 0x7f7f
	ori $5 $5 0x7f7f
	bne $4 $5 fail

#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sw2_
#	syscall
#
#	sw $3 1000000($sp)
#	sw $3 1000001($sp)


	.data
swl_:	.asciiz "Testing SWL\n"
	.align 2
swld_:	.word 0 0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 swl_
	lui $a0, 0x1000
	ori $a0 $a0 0x25c
	syscall

#	la $2 swld_
	lui $2, 0x1000
	ori $2 $2 0x26c
#       addi $3 $0 0x01000000
	lui $3 0x0100
	ori $3 $3 0x0000
	swl $3 0($2)
	lw $4 0($2)
	ori $5 $0 0x1
	bne $4 $5 fail

#	addi $3 $0 0x01020000
	lui $3 0x0102
	ori $3 $3 0x0000
	swl $3 1($2)
	lw $4 0($2)
	ori $5 $0  0x0102
	bne $4 $5 fail

#	addi $3 $0 0x01020300
	lui $3 0x0102
	ori $3 $3 0x0300
	swl $3 2($2)
	lw $4 0($2)
	lui $5 0x01
	ori $5 $5 0x0203
	bne $4 $5 fail

#	addi $3 $0 0x01020304
	lui $3 0x0102
	ori $3 $3 0x0304
	swl $3 3($2)
	lw $4 0($2)
	lui $5 0x0102
	ori $5 $5 0x0304
	bne $4 $5 fail
	addu $0 $0 $0         # Nop


	.data
swr_:	.asciiz "Testing SWR\n"
	.align 2
swrd_:	.word 0 0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 swr_
	lui $a0, 0x1000
	ori $a0 $a0 0x274
	syscall

#	la $2 swrd_
	lui $2, 0x1000
	ori $2 $2 0x284
	addi $3 $0 1
	swr $3 0($2)
	lw $4 0($2)
	ori $5 $0 1
	bne $4 $5 fail

	addi $3 $0 0x0102
	swr $3 1($2)
	lw $4 0($2)
	lui $5 0x1
	ori $5 $5 0x0201
	bne $4 $5 fail

#	addi $3 $0 0x010203
	lui $3 0x01
	ori $3 $3 0x0203
	swr $3 2($2)
	lw $4 0($2)
	lui $5 0x203
	ori $5 $5 0x0201
	bne $4 $5 fail

#	addi $3 $0 0x01020304
	lui $3 0x0102
	ori $3 $3 0x0304
	swr $3 3($2)
	lw $4 0($2)
	lui $5 0x403
	ori $5 $5 0x0201
	bne $4 $5 fail
	addu $0 $0 $0                     #Nop


	.data
xor_:	.asciiz "Testing XOR\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 xor_
	lui $a0, 0x1000
	ori $a0 $a0 0x28c
	syscall

	addi $2 $0 1
	addi $3 $0 -1

	xor $4 $0 $0
	bne $4 $0 fail
	xor $4 $3 $3
	bne $4 $0 fail
	xor $4 $2 $3
	lui $5 0xffff
	ori $5 $5 0xfffe
	bne $4 $5 fail
	addu $0 $0 $0                #Nop

	.data
xori_:	.asciiz "Testing XORI\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 xori_
	lui $a0, 0x1000
	ori $a0 $a0 0x299
	syscall

	addi $2 $0 1
	ori $3 $0 -1

	xori $4 $0 0
	bne $4 $0 fail
	xori $4 $3 -1
	bne $4 $0 fail
	xori $4 $2 -1
#	lui $5 0xffff
	ori $5 $0 0xfffe
	bne $4 $5 fail

	.data
jal_:	.asciiz "Testing JAL\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 jal_
	lui $a0, 0x1000
	ori $a0 $a0 0x2a7
	syscall

	jal l18
	addu $0 $0 $0                # Nop
l19:	j l20                        # 0x00400ea0
	addu $0 $0 $0                # Nop
l18:	lui $4 0x0040                # to replace la $4 l19
	ori $4 $4 0x0eb0             # bare machine has a delay slot.
	bne $31 $4 fail
	addu $0 $0 $0                #Nop
	jr $31
	addu $0 $0 $0                #Nop
l20:   	addu $0 $0 $0                #Nop  -- 0x00400ebc


	.data
jalr_:	.asciiz "Testing JALR\n"
#jalr2_:	.asciiz "Expect an non-word boundary exception:\n  "
	.text
	addi $v0 $0 4	# syscall 4 (print_str) 0x00400ec0
#	la $a0 jalr_
	lui $a0, 0x1000
	ori $a0 $a0 0x2b4
	syscall

#	la $2 l21
	lui $2 0x0040                # 0x00400ed0
	ori $2 $2 0x0ef4
	addu $4 $0 $2
	jalr $3, $2
	addu $0 $0 $0                #Nop -- 00400ee0
l23:	j l22
l21:	addu $0 $0 $0             # la $4 l21  -- delay slot.
	bne $3 $4 fail
	addu $0 $0 $0             # Nop  -- 00400ef0
	jr $3
l22:	addu $0 $0 $0             # Nop

#       li $v0 4	# syscall 4 (print_str)
#	la $a0 jalr2_
#	syscall
#	la $2 l24
#	add $2 $2 2
# l24:	jalr $3 $2


	.data
bgezal_:.asciiz "Testing BGEZAL\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 bgezal_
	lui $a0, 0x1000           # 00400f00
	ori $a0 $a0 0x2c2
	syscall

	addi $2 $0 -1
	addi $3 $0 1              # 00400f10

	bgezal $0 l5
	addu $0 $0 $0             # Nop
	j fail
	addu $0 $0 $0             # Nop -- 00400f20
l5:	bgezal $2 fail
	addu $0 $0 $0             # Nop
	bgezal $3 l6
	addu $0 $0 $0             # Nop -- 00400f30
l55:	j fail
	addu $0 $0 $0             # Nop
l6:	lui $4 0x0040             #  la $4 l55
	ori $4 $4 0x0f48          # 00400f40
	bne $31 $4 fail
	addu $0 $0 $0             # Nop

	.data
bltzal_:.asciiz "Testing BLTZAL\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 bltzal_
	lui $a0, 0x1000           # 00400f50
	ori $a0 $a0 0x2d2
	syscall

	addi $2 $0 -1
	addi $3 $0 1              # 00400f60

	bltzal $0 fail
	addu $0 $0 $0          # Nop
	bltzal $3 fail
	addu $0 $0 $0          # Nop --  00400f70
l13:	bltzal $2 l15
	addu $0 $0 $0          # Nop
l14:	j fail
	addu $0 $0 $0          # Nop --  00400f80
l15:	lui $4 0x0040          # la $4 l14
	ori $4 $4 0x0f90
	bne $31 $4 fail
	addu $0 $0 $0          # Nop --  00400f90

# Testing the exceptions

	.data
break_:	.asciiz "Testing BREAK\nExpect an exception message:\n  "
#	.text
#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 break_
#	lui $a0, 0x1000
#	ori $a0 $a0 0x2e2
#	syscall

#	break 3


	.data
ccp_:	.asciiz "Testing move to/from coprocessor control z\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 ccp_
	lui $a0, 0x1000
	ori $a0 $a0 0x310
	syscall

#	li $2 0x7f7f
	addi $2 $0 0x7f7f
	ctc0 $2 $3
	addu $0 $0 $0                #Nop
	cfc0 $4 $3
	addu $0 $0 $0                #Nop
	bne $2 $4 fail
#	li $2 0x7f7f
#       Skip floating point stuff for now.
#	addi $2 $0 0x7f7f
#	ctc1 $2 $3
#	addu $0 $0 $0                #Nop
#	cfc1 $4 $3
#	addu $0 $0 $0                #Nop
#	bne $2 $4 fail
#	li $2 0x7f7f
	addi $2 $0 0x7f7f
	ctc2 $2 $3
	addu $0 $0 $0                #Nop
	cfc2 $4 $3
	addu $0 $0 $0                #Nop
	bne $2 $4 fail
#	li $2 0x7f7f
	addi $2 $0 0x7f7f
	ctc3 $2 $3
	addu $0 $0 $0                #Nop
	cfc3 $4 $3
	addu $0 $0 $0                #Nop
	bne $2 $4 fail
	addu $0 $0 $0            # Nop


	.data
mcp_:	.asciiz "Testing move to/from coprocessor z\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 mcp_
	lui $a0, 0x1000
	ori $a0 $a0 0x33c
	syscall

#	li $2 0x7f7f
	addi $2 $0 0x7f7f
	mtc0 $2 $3
	addu $0 $0 $0            # Nop
	mfc0 $4 $3
	addu $0 $0 $0            # Nop
	bne $2 $4 fail
#       Skip FP for now.
#	li $2 0x7f7f
#	addi $2 $0 0x7f7f
#	mtc1 $2 $3
#	addu $0 $0 $0            # Nop
#	mfc1 $4 $f3
#	addu $0 $0 $0            # Nop
#	bne $2 $4 fail

#	li $2 0x7f7f
#	addi $2 $0 0x7f7f
#	li $3 0xf7f7
#	addi $3 $0 0x7f7f
#	mtc1.d $2 $4
#	mfc1.d $6 $4
#	bne $2 $6 fail
#	bne $3 $7 fail

#	li $2 0x7f7f
	addi $2 $0 0x7f7f
	mtc2 $2 $3
	addu $0 $0 $0            # Nop
	mfc2 $4 $3
	addu $0 $0 $0            # Nop
	bne $2 $4 fail
#	li $2 0x7f7f
	addi $2 $0 0x7f7f
	mtc3 $2 $3
	addu $0 $0 $0            # Nop
	mfc3 $4 $3
	addu $0 $0 $0            # Nop
	bne $2 $4 fail
	addu $0 $0 $0            # Nop


	.data
hilo_:	.asciiz "Testing move to/from HI/LO\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 hilo_
	lui $a0, 0x1000
	ori $a0 $a0 0x360
	syscall

	mthi $0
	mfhi $2
	bne $2 $0 fail
	mtlo $0
	mflo $2
	bne $2 $0 fail
#	li $2 1
	addi $2 $0 1
	mthi $2
	mfhi $3
	bne $3 $2 fail
#	li $2 1
	addi $2 $0 1
	mtlo $2
	mflo $3
	bne $3 $2 fail
#	li $2 -1
	addi $2 $0 -1
	mthi $2
	mfhi $3
	bne $3 $2 fail
#	li $2 -1
	addi $2 $0 1
	mtlo $2
	mflo $3
	bne $3 $2 fail
	addu $0 $0 $0            # Nop

	.data
lswc_:	.asciiz "Testing load/store word coprocessor z\n"
	.align 2
lswcd_:	.byte 0, 0, 0, 0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 lswc_
	lui $a0, 0x1000
	ori $a0 $a0 0x37c
	syscall

#	li $3, 0x7f7f7f7f
	lui $3 0x7f7f
	ori $3 $3 0x7f7f
#	la $2 lswcd_
	lui $2, 0x1000
	ori $2 $2 0x3a4
	mtc0 $3, $0
	addu $0 $0 $0           #Nop
	swc0 $0 0($2)
	lw $4 0($2)
	addu $0 $0 $0           #Nop
	bne $4 $3 fail
	lwc0 $1 0($2)
	addu $0 $0 $0           #Nop
	mfc0 $5, $1
	addu $0 $0 $0           #Nop
	bne $5 $3 fail
	addu $0 $0 $0           #Nop

#	li $3, 0x7f7f7f7f
#	lui $3 0x7f7f
#	ori $3 $3 0x7f7f
#	la $2 lswcd_
#	lui $2, 0x1000
#	ori $2 $2 0x3a4
#	mtc1 $3, $0
#	addu $0 $0 $0           #Nop
#	swc1 $f0 0($2)
#	lw $4 0($2)
#	addu $0 $0 $0           #Nop
#	bne $4 $3 fail
#	lwc1 $f1 0($2)
#	addu $0 $0 $0           #Nop
#	mfc1 $5, $f1
#	addu $0 $0 $0           #Nop
#	bne $5 $3 fail

#	li $3, 0x7f7f7f7f
	lui $3 0x7f7f
	ori $3 $3 0x7f7f
#	la $2 lswcd_
	lui $2, 0x1000
	ori $2 $2 0x3a4
	mtc2 $3, $0
	addu $0 $0 $0           #Nop
	swc2 $0 0($2)
	lw $4 0($2)
	addu $0 $0 $0           #Nop
	bne $4 $3 fail
	lwc2 $1 0($2)
	addu $0 $0 $0           #Nop
	mfc2 $5, $1
	addu $0 $0 $0           #Nop
	bne $5 $3 fail
	addu $0 $0 $0           #Nop

#	li $3, 0x7f7f7f7f
	lui $3 0x7f7f
	ori $3 $3 0x7f7f
#	la $2 lswcd_
	lui $2, 0x1000
	ori $2 $2 0x3a4
	mtc3 $3, $0
	addu $0 $0 $0           #Nop
	swc3 $0 0($2)
	lw $4 0($2)
	addu $0 $0 $0           #Nop
	bne $4 $3 fail
	addu $0 $0 $0           #Nop
	lwc3 $1 0($2)
	addu $0 $0 $0           #Nop
	mfc3 $5, $1
	addu $0 $0 $0           #Nop
	bne $5 $3 fail
	addu $0 $0 $0           #Nop


# Done !!!
	.data
pt:	.asciiz "Passed all tests\n"
	.text
	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 sm
	lui $a0, 0x1000
	ori $a0 $a0 0x3a8
	syscall
	lui $4 0x1000
	lw $31 0($4)
	addu $0 $0 $0		# Nop
	jr $31		# Return from main




#	.data
#fm:	.asciiz "Failed test\n"
	.text
fail:	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 fm
	lui $a0, 0x1000
	ori $a0 $a0 0x4
	syscall
	addi $2 $0 10	# syscall 10 (exit)
	syscall
	addu $0 $0 $0		# Nop
	addu $0 $0 $0		# Nop
	addu $0 $0 $0		# Nop
	addu $0 $0 $0		# Nop





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
	addiu $v0, $0, 4	# syscall 4 (print_str)
#	la $a0 __m1_
	lui $a0, 0x1000
	ori $a0 $a0 0x03e5
	syscall
	addiu $v0, $0, 1	# syscall 1 (print_int)
	addu $a0 $0 $26
	syscall
	addiu $v0, $0, 4	# syscall 4 (print_str)
#	la $a0 __m2_
	lui $a0, 0x1000
	ori $a0, $a0, 0x03f1
	syscall
	mtc0 $0, $13		# Clear Cause register
	rfe			# Return from exception handler
	addiu $27 $27 4		# Return to next instruction
	jr $27




