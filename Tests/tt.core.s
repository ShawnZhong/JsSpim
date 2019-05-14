# SPIM S20 MIPS simulator.
# A torture test for the SPIM simulator.
# Core tests for instructions that do not differ on big and little endian systems.
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


	.data
saved_ret_pc:	.word 0		# Holds PC to return from main
m3:	.asciiz "The next few lines should contain exception error messages\n"
m4:	.asciiz "Done with exceptions\n\n"
	.text
	.globl main
main:
	sw $31 saved_ret_pc

#
# The first thing to do is to test the exceptions:
#
	li $v0 4	# syscall 4 (print_str)
	la $a0 m3
	syscall

# Exception 1 (INT) -- Not implemented yet
# Exception 4 (ADEL)
	li $t0 0x400000
	lw $3 1($t0)
# Exception 5 (ADES)
	sw $3 1($t0)
# Exception 6 (IBUS) -- Can't test and continue
# Exception 7 (DBUS)
	lw $3 10000000($t0)
# Exception 8 (SYSCALL) -- Not implemented
# Exception 9 (BKPT)
	break 0
# Exception 10 (RI) -- Not implemented (can't enter bad instructions)
# Exception 12 (overflow)
	li $t0 0x7fffffff
	add $t0 $t0 $t0
	li $v0 4	# syscall 4 (print_str)
	la $a0 m4
	syscall

#
# Try modifying R0
#
	add $0, $0, 1
	bnez $0 fail


#
# Test the timer:
#
	.data
timer_:	.asciiz "Testing timer\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 timer_
	syscall

	mtc0 $0 $9	# Clear count register
timer1_:
	mfc0 $9 $9
	bne $9 10 timer1_# Count up to 10


#
# Test .ASCIIZ
#
	.data
asciiz_:.asciiz "Testing .asciiz\n"
str0:	.asciiz ""
str1:	.asciiz "a"
str2:	.asciiz "bb"
str3:	.asciiz "ccc"
str4:	.asciiz "dddd"
str5:	.asciiz "eeeee"
str06:	.asciiz "", "a", "bb", "ccc", "dddd", "eeeee"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 asciiz_
	syscall

	la $a0 str0
	li $a1 6
	jal ck_strings

	la $a0 str06
	li $a1 6
	jal ck_strings

	j over_strlen


ck_strings:
	move $s0 $a0
	move $s1 $ra
	li $s2 0

l_asciiz1:
	move $a0 $s0
	jal strlen

	bne $v0 $s2 fail

	add $s0 $s0 $v0	# skip string
	add $s0 $s0 1	# skip null byte

	add $s2 1
	blt $s2 $a1 l_asciiz1

	move $ra $s1
	jal $ra


strlen:
	li $v0 0	# num chars
	move $t0 $a0	# str pointer

l_strlen1:
	lb $t1 0($t0)
	add $t0 1
	add $v0 1
	bnez $t1 l_strlen1

	sub $v0 $v0 1	# don't count null byte
	jr $31

over_strlen:

#
# Now, test each instruction
#

	.data
add_:	.asciiz "Testing ADD\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 add_
	syscall

	li $2 1
	li $3 -1

	add $4, $0, $0
	bnez $4 fail
	add $4, $0, $2
	bne $4 1 fail
	add $4, $4, $3
	bnez $4 fail


	.data
addi_:	.asciiz "Testing ADDI\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 addi_
	syscall

	addi $4, $0, 0
	bnez $4 fail
	addi $4, $0, 1
	bne $4 1 fail
	addi $4, $4, -1
	bnez $4 fail


	.data
addiu_:	.asciiz "Testing ADDIU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 addiu_
	syscall

	addiu $4, $0, 0
	bnez $4 fail
	addiu $4, $0, 1
	bne $4 1 fail
	addiu $4, $4, -1
	bnez $4 fail

	li $2 0x7fffffff
	addiu $2 $2 2	# should not trap
	bne $2 0x80000001 fail


	.data
addu_:	.asciiz "Testing ADDU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 addu_
	syscall

	li $2 1
	li $3 -1

	addu $4, $0, $0
	bnez $4 fail
	addu $4, $0, $2
	bne $4 1 fail
	addu $4, $4, $3
	bnez $4 fail

	li $2 0x7fffffff
	addu $2 $2 $2		# should not trap
	bne $2 -2 fail


	.data
and_:	.asciiz "Testing AND\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 and_
	syscall

	li $2 1
	li $3 -1

	and $4 $0 $0
	bnez $4 fail
	and $4 $2 $2
	beqz $4 fail
	and $4 $2 $3
	bne $4 1 fail


	.data
andi_:	.asciiz "Testing ANDI\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 andi_
	syscall

	li $2 1
	li $3 -1

	andi $4 $0 0
	bnez $4 fail
	and $4 $2 1
	beqz $4 fail
	and $4 $2 -1
	bne $4 1 fail
	and $4 $3 -1
	bne $4 $3 fail


	.data
beq_:	.asciiz "Testing BEQ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 beq_
	syscall

	li $2 -1
	li $3 1

	beq $0 $0 l1
	j fail
l1:	beq $2 $2 l2
	j fail
l2:	beq $3 $2 fail

	beq $2 $2 far_away	# Check long branch
	j fail
come_back:

	li $2 3
l2_1:	sub $2 $2 1
	bnez $2, l2_1


	.data
bgez_:	.asciiz "Testing BGEZ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bgez_
	syscall

	li $2 -1
	li $3 1

	bgez $0 l3
	j fail
l3:	bgez $3 l4
	j fail
l4:	bgez $2 fail


	.data
bgezal_:.asciiz "Testing BGEZAL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bgezal_
	syscall

	li $2 -1
	li $3 1

	bgezal $0 l5
	j fail
	bgezal $2 fail
l5:	bgezal $3 l6
l55:	j fail
l6:	la $4 l55
	bne $31 $4 fail


	.data
bgtz_:	.asciiz "Testing BGTZ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bgtz_
	syscall

	li $2 -1
	li $3 1

	bgtz $0 fail
l7:	bgtz $3 l8
	j fail
l8:	bgtz $2 fail


	.data
blez_:	.asciiz "Testing BLEZ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 blez_
	syscall

	li $2 -1
	li $3 1

	blez $0 l9
	j fail
l9:	blez $2 l10
	j fail
l10:	blez $3 fail


	.data
bltz_:	.asciiz "Testing BLTZ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bltz_
	syscall

	li $2 -1
	li $3 1

	bltz $0 fail
l11:	bltz $2 l12
	j fail
l12:	bltz $3 fail


	.data
bltzal_:.asciiz "Testing BLTZAL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bltzal_
	syscall

	li $2 -1
	li $3 1

	bltzal $0 fail
	bltzal $3 fail
l13:	bltzal $2 l15
l14:	j fail
l15:	la $4 l14
	bne $31 $4 fail


	.data
bne_:	.asciiz "Testing BNE\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bne_
	syscall

	li $2 -1
	li $3 1

	bne $0 $0 fail
	bne $2 $2 fail
	bne $3 $2 l16
l16:


	.data
break_:	.asciiz "Testing BREAK\nExpect a exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 break_
	syscall

	break 3


# COPz is not checked


	.data
ccp_:	.asciiz "Testing move to/from coprocessor control 0/1\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ccp_
	syscall

	li $2 0x7f7f
	ctc0 $2 $3
	cfc0 $4 $3
	bne $2 $4 fail
	li $2 0x7f7f
	ctc1 $2 $3
	cfc1 $4 $3
	bne $2 $4 fail


	.data
clo_:	.asciiz "Testing CLO\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 clo_
	syscall

	li $2 0
	clo $3 $2
	bne $3 0 fail

	li $2 0xffffffff
	clo $3 $2
	bne $3 32 fail

	li $2 0xf0000000
	clo $3 $2
	bne $3 4 fail


	.data
clz_:	.asciiz "Testing CLZ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 clz_
	syscall

	li $2 0
	clz $3 $2
	bne $3 32 fail

	li $2 0xffffffff
	clz $3 $2
	bne $3 0 fail

	li $2 0x0fff0000
	clz $3 $2
	bne $3 4 fail


	.data
div_:	.asciiz "Testing DIV\n"
div2_:	.asciiz "Expect exception caused by divide by 0:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 div_
	syscall

	li $2 4
	li $3 2
	li $4 -2

	div $5 $2 $3
	bne $5 2 fail
	mfhi $5
	bne $5 0 fail

	div $5 $2 $4
	bne $5 -2 fail
	mfhi $5
	bne $5 0 fail

	li $2 0x80000000
	li $4 0xffffffff
	div $5 $2 $4	# Overflows, but should not cause overflow

	li $2 1
	li $4 0xffffffff
	div $5 $2 $4
	bne $5 -1 fail
	mfhi $5
	bne $5 0 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 div2_
	syscall
	div $5 $2 $0


	.data
divu_:	.asciiz "Testing DIVU\n"
divu2_:	.asciiz "Expect exception caused by divide by 0:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 divu_
	syscall

	li $2 4
	li $3 2
	li $4 -2

	divu $5 $2 $3
	bne $5 2 fail
	mfhi $5
	bne $5 0 fail

	divu $0 $2 $3
	mflo $5
	bne $5 2 fail
	mfhi $5
	bne $5 0 fail

	divu $5 $2 $4
	bne $5 0 fail
	mfhi $5
	bne $5 4 fail

	li $2 0x80000000
	li $4 0xffffffff
	divu $5 $2 $4	# Overflows, but should not cause overflow

	li $2 1
	li $4 0xffffffff
	divu $5 $2 $4
	bne $5 0 fail
	mfhi $5
	bne $5 1 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 divu2_
	syscall
	divu $5 $2 $0


	.data
j_:	.asciiz "Testing J\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 j_
	syscall

	j l17
	j fail

	.ktext
	nop		# These instructions aren't executed, but
	j l17a		# cause parser errors since high 4 bits
l17a:			# don't match
	j l17b

	.text
l17b:	nop
	j l17a	# Correctly flagged as error here.

l17:


	.data
jal_:	.asciiz "Testing JAL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 jal_
	syscall

	jal l18
l19:	j l20
l18:	la $4 l19
	bne $31 $4 fail
	jr $31
l20:


	.data
jalr_:	.asciiz "Testing JALR\n"
jalr2_:	.asciiz "Expect an non-word boundary exception:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 jalr_
	syscall

	la $2 l21
	jalr $3, $2
l23:	j l22
l21:	la $4 l23
	bne $3 $4 fail
	jr $3

l22:	la $2 l21a
	jalr $2
l23a:	j l22a
l21a:	la $4 l23a
	bne $31 $4 fail
	jr $31

l22a:	li $v0 4	# syscall 4 (print_str)
	la $a0 jalr2_
	syscall
	la $2 l24
	add $2 $2 2
l24:	jalr $3 $2


	.data
jr_:	.asciiz "Testing JR\n"
jr2_:	.asciiz "Expect an non-word boundary exception:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 jr_
	syscall

	la $2 l25
	jr $2
	j fail
l25:	li $v0 4	# syscall 4 (print_str)
	la $a0 jr2_
	syscall
	la $2 l27
	add $2 $2 2
l27:	jr $2


	.data
la_:	.asciiz "Testing LA\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 la_
	syscall

	# Simple cases already tested
	li $4 101
	la $5 10($4)
	bne $5 111 fail


# LB is endian-specific


# LBU is endian-specific


	.data
ld_:	.asciiz "Testing LD\n"
ld2_:	.asciiz "Expect four address error exceptions:\n"
ldd_:	.word 1, -1, 0, 0x8000000
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ld_
	syscall

	la $2 ldd_
	ld $3 0($2)
	bne $3 1 fail
	bne $4 -1 fail
	ld $3 8($2)
	bne $3 0 fail
	bne $4 0x8000000 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 ld2_
	syscall

	li $t5 0x7fffffff
	ld $3 1000($t5)
	ld $3 1001($t5)


# LDC2 not tested

# LWC2 not tested

	.data
lh_:	.asciiz "Testing LH\n"
lh2_:	.asciiz "Expect two address error exceptions:\n"
lhd_:	.half 1, -1, 0, 0x8000
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lh_
	syscall

	la $2 lhd_
	lh $3 0($2)
	bne $3 1 fail
	lh $3 2($2)
	bne $3 -1 fail
	lh $3 4($2)
	bne $3 0 fail
	lh $3 6($2)
	bne $3 0xffff8000 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 lh2_
	syscall

	li $t5 0x7fffffff
	lh $3 1000($t5)
	lh $3 1001($t5)

	.data
lhu_:	.asciiz "Testing LHU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lhu_
	syscall

	la $2 lhd_
	lhu $3 0($2)
	bne $3 1 fail
	lhu $3 2($2)
	bne $3 0xffff fail
	lhu $3 4($2)
	bne $3 0 fail
	lhu $3 6($2)
	bne $3 0x8000 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 lh2_
	syscall

	li $t5 0x7fffffff
	lhu $3 1000($t5)
	lhu $3 1001($t5)


	.data
ll_:	.asciiz "Testing LL\n"
ll1:	.word 10
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ll_
	syscall

	ll $2 ll1
	bne $2 10 fail
	add $2 $2 1
	sc $2 ll1
	lw $3 ll1
	bne $2 $3 fail

	.data
lui_:	.asciiz "Testing LUI\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lui_
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
	lui $2 0xffff
	srl $2 $2 16
	addiu $2 $2 1
	andi $2 $2 0xffff
	bne $2 $0 fail


	.data
lw_:	.asciiz "Testing LW\n"
lwd_:	.word 1, -1, 0, 0x8000000
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lw_
	syscall

	la $2 lwd_
	lw $3 0($2)
	bne $3 1 fail
	lw $3 4($2)
	bne $3 -1 fail
	lw $3 8($2)
	bne $3 0 fail
	lw $3 12($2)
	bne $3 0x8000000 fail

	li $2, 0
	lw $3 lwd_($2)
	bne $3 1 fail
	addi $2, $2, 4
	lw $3 lwd_($2)
	bne $3 -1 fail
	addi $2, $2, 4
	lw $3 lwd_($2)
	bne $3 0 fail
	addi $2, $2, 4
	lw $3 lwd_($2)
	bne $3 0x8000000 fail

	la $2 lwd_
	add $2 $2 12
	lw $3 -12($2)
	bne $3 1 fail
	lw $3 -8($2)
	bne $3 -1 fail
	lw $3 -4($2)
	bne $3 0 fail
	lw $3 0($2)
	bne $3 0x8000000 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 lh2_
	syscall

	li $t5 0x7fffffff
	lw $3 1000($t5)
	lw $3 1001($t5)


# LWL is endian-specific


# LWR is endian-specific


	.data
madd_:	.asciiz "Testing MADD\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 madd_
	syscall

	mthi $0
	mtlo $0
	madd $0, $0
	mfhi $3
	bnez $3 fail
	mflo $3
	bnez $3 fail

        mtlo $0
        mthi $0
	li $4, 1
	madd $4, $4
	mfhi $3
	bnez $3 fail
	mflo $3
	bne $3 1 fail

	li $3, 1
        mtlo $3
        mthi $0
	li $4, -1
	madd $3, $4
	mfhi $3
	bnez $3 fail
	mflo $3
	bnez $3 fail

        mtlo $0
        mthi $0
        li $3, 1
        li $4, -1
        madd $3, $4
        mfhi $3
	bne $3 0xffffffff fail
	mflo $3
	bne $3 0xffffffff fail

	li $t0 1
	mtlo $t0
	mthi $0
	li $t0 2
	li $t1 -1
        madd $t0, $t1
        mfhi $3
	bne $3 0xffffffff fail
	mflo $3
	bne $3 0xffffffff fail

        mtlo $0
        mthi $0
	li $4, 0x10000
	madd $4, $4
	mfhi $3
	bne $3 1 fail
	mflo $3
	bne $3 0 fail

	li $4, 0x10000
	madd $4 $4
	mfhi $3
	bne $3 2 fail
	mflo $3
	bne $3 0 fail

	.data
maddu_:	.asciiz "Testing MADDU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 maddu_
	syscall

	mthi $0
	mtlo $0

	maddu $0 $0
	mfhi $3
	bnez $3 fail
	mflo $3
	bnez $3 fail

	li $4, 1
	maddu $4 $4
	mfhi $3
	bnez $3 fail
	mflo $3
	bne $3 1 fail

	li $4, -1
	maddu $4 $4
	mfhi $3
	bne $3 0xfffffffe fail
	mflo $3
	bne $3 2 fail

	.data
mcp_:	.asciiz "Testing move to/from coprocessor z\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 mcp_
	syscall

	li $2 0x7f7f
	mtc0 $2 $3
	mfc0 $4 $3
	bne $2 $4 fail
	li $2 0x7f7f
	mtc1 $2 $3
	mfc1 $4 $f3
	bne $2 $4 fail
	li $2 0x7f7f
	li $3 0xf7f7
	mtc1.d $2 $4
	mfc1.d $6 $4
	bne $2 $6 fail
	bne $3 $7 fail


	.data
hilo_:	.asciiz "Testing move to/from HI/LO\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 hilo_
	syscall

	mthi $0
	mfhi $2
	bnez $2 fail
	mtlo $0
	mflo $2
	bnez $2 fail
	li $2 1
	mthi $2
	mfhi $3
	bne $3 $2 fail
	li $2 1
	mtlo $2
	mflo $3
	bne $3 $2 fail
	li $2 -1
	mthi $2
	mfhi $3
	bne $3 $2 fail
	li $2 -1
	mtlo $2
	mflo $3
	bne $3 $2 fail


	.data
movf_:	.asciiz "Testing MOVF\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movf_
	syscall

	li $2 0x70
	ctc1 $2 $25
	li $2 1
	li $3 0
	li $4 2
	movf $3 $2 1
	bne $3 1 fail
	movf $3 $4 6
	bne $3 1 fail


	.data
movn_:	.asciiz "Testing MOVN\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movn_
	syscall

	li $2 2
	li $3 3
	li $4 4
	movn $4 $3 $0
	bne $4 4 fail
	movn $4 $3 $2
	bne $4 3 fail


	.data
movt_:	.asciiz "Testing MOVT\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movt_
	syscall

	li $2 0x70
	ctc1 $2 $25
	li $2 1
	li $3 0
	li $4 2
	movt $3 $2 1
	bne $3 0 fail
	movt $3 $4 6
	bne $3 2 fail


	.data
movz_:	.asciiz "Testing MOVZ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movz_
	syscall

	li $2 2
	li $3 3
	li $4 4
	movz $4 $3 $2
	bne $4 4 fail
	movz $4 $3 $0
	bne $4 3 fail


	.data
msub_:	.asciiz "Testing MSUB\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 msub_
	syscall

	mthi $0
	mtlo $0
	msub $0 $0
	mfhi $3
	bnez $3 fail
	mflo $3
	bnez $3 fail

	mthi $0
	mtlo $0
	li $4, 1
	msub $4 $4
	mfhi $3
	bne $3 0xffffffff fail
	mflo $3
	bne $3 0xffffffff fail

	li $4, 1
	msub $3 $4
	mfhi $3
	bnez $3 fail
	mflo $3
	bnez $3 fail

	mthi $0
	mtlo $0
	li $4, 0x10000
	msub $4 $4
	mfhi $3
	bne $3 0xffffffff fail
	mflo $3
	bne $3 0 fail

	mtlo $0
	mthi $0
	li $4, 1
	li $5, -1
	msub $5, $4
	mfhi $3
	bne $3 0 fail
	mflo $3
	bne $3 1 fail

	.data
msubu_:	.asciiz "Testing MSUBU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 msubu_
	syscall

	mthi $0
	mtlo $0
	msubu $0 $0
	mfhi $3
	bnez $3 fail
	mflo $3
	bnez $3 fail

	mthi $0
	mtlo $0
	li $4, 1
	msubu $4 $4
	mfhi $3
	bne $3 0xffffffff fail
	mflo $3
	bne $3 0xffffffff fail

	mtlo $0
	mthi $0
	li $4, 1
	li $5, -1
	msubu $5, $4
	mfhi $3
	bne $3 0xffffffff fail
	mflo $3
	bne $3 1 fail

	.data
mul_:	.asciiz "Testing MUL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 mul_
	syscall

	li $2, 1
	mul $3, $2, 0
	bnez $3 fail
	mul $3, $2, 1
	bne $3 1 fail
	mul $3, $2, 10
	bne $3 10 fail

	mul $2 $0 $0
	bnez $2 fail
	mfhi $3
	bnez $3 fail
	mflo $3
	bnez $3 fail

	li $4, 1
	mul $2 $4 $4
	bne $2 1 fail
	mfhi $3
	bnez $3 fail
	mflo $3
	bne $3 1 fail

	li $4, -1
	mul $2 $4 $4
	bne $2 1 fail
	mfhi $3
	bnez $3 fail
	mflo $3
	bne $3 1 fail

	li $4, -1
	li $5, 1
	mul $2 $4 $5
	bne $2 -1 fail
	mfhi $3
	bne $3 -1 fail
	mflo $3
	bne $3 -1 fail

	li $4, 0x10000
	mul $2 $4 $4
	bne $2 0 fail
	mfhi $3
	bne $3 1 fail
	mflo $3
	bne $3 0 fail

	li $4, 0x80000000
	mul $2 $4 $4
	bne $2 0 fail
	mfhi $3
	bne $3 0x40000000 fail
	mflo $3
	bne $3 0 fail


	.data
multu_:	.asciiz "Testing MULTU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 multu_
	syscall

	multu $0 $0
	mfhi $3
	bnez $3 fail
	mflo $3
	bnez $3 fail

	li $4, 1
	multu $4 $4
	mfhi $3
	bnez $3 fail
	mflo $3
	bne $3 1 fail

	li $4, -1
	multu $4 $4
	mfhi $3
	bne $3 0xfffffffe fail
	mflo $3
	bne $3 1 fail

	li $4, -1
	li $5, 0
	multu $4 $5
	mfhi $3
	bne $3 0 fail
	mflo $3
	bne $3 0 fail

	li $4, -1
	li $5, 1
	multu $4 $5
	mfhi $3
	bne $3 0 fail
	mflo $3
	bne $3 -1 fail

	li $4, 0x10000
	multu $4 $4
	mfhi $3
	bne $3 1 fail
	mflo $3
	bne $3 0 fail

	li $4, 0x80000000
	multu $4 $4
	mfhi $3
	bne $3 0x40000000 fail
	mflo $3
	bne $3 0 fail

	li $3, 0xcecb8f27
	li $4, 0xfd87b5f2
	multu $3 $4
	mfhi $3
	bne $3 0xcccccccb fail
	mflo $3
	bne $3 0x7134e5de fail


	.data
mulo_:	.asciiz "Testing MULO\n"
mulo1_:	.asciiz "Expect an exception:\n	 "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 mulo_
	syscall

	mulo $2 $0 $0
	bne $2 0 fail

	li $4, 1
	mulo $2 $4 $4
	bne $2 1 fail

	li $4, -1
	mulo $2 $4 $4
	bne $2 1 fail

	li $4, -1
	li $5, 1
	mulo $2 $4 $5
	bne $2 -1 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 mulo1_
	syscall

	li $4, 0x10000
	mulo $2 $4 $4
	bne $2 0 fail


	.data
nor_:	.asciiz "Testing NOR\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 nor_
	syscall

	li $2 1
	li $3 -1

	nor $4 $0 $0
	bne $4 -1 fail
	nor $4 $2 $2
	bne $4 0xfffffffe fail
	nor $4 $2 $3
	bne $4 0 fail


	.data
or_:	.asciiz "Testing OR\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 or_
	syscall

	li $2 1
	li $3 -1

	or $4 $0 $0
	bne $4 0 fail
	or $4 $2 $2
	bne $4 1 fail
	or $4 $2 $3
	bne $4 -1 fail


	.data
ori_:	.asciiz "Testing ORI\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ori_
	syscall

	li $2 1
	li $3 -1

	ori $4 $0 0
	bne $4 0 fail
	ori $4 $2 1
	bne $4 1 fail
	ori $4 $2 0xffff
	bne $4 0x0000ffff fail


# RFE tested previously


	.data
sp_:    .asciiz "Testing .space\n"
spd_:   .space 100000
spde_:  .word 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sd_
	syscall

        la $2 spde_
        sub $2 $2 4
        lw $3 0($2)     # look for exception


# SB is endian-specific


	.data
sd_:	.asciiz "Testing SD\n"
sd2_:	.asciiz "Expect two address error exceptions:\n"
	.align 2
sdd_:	.word 0, 0, 0, 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sd_
	syscall

	li $3, 0x7f7f7f7f
	li $4, 0xf7f7f7f7
	la $2 sdd_
	sd $3 0($2)
	ld $5 0($2)
	bne $3 $5 fail
	bne $4 $4 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 sd2_
	syscall

	li $t5 0x7fffffff
	sd $3 1000($t5)
	sd $3 1001($t5)


	.data
swc1_:	.asciiz "Testing SWC1\n"
	.align 2
swc1d_:	.word 0, 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 swc1_
	syscall

	li $3, 0x7f7f7f7f
	la $2 swc1d_
	mtc1 $3, $0
	swc1 $f0 0($2)
	lw $5 0($2)
	bne $5 $3 fail


	.data
s.s_:	.asciiz "Testing S.S\n"
	.align 2
s.sd_:	.word 0, 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 s.s_
	syscall

	li $3, 0x7f7f7f7f
	la $2 s.sd_
	mtc1 $3, $0
	s.s $f0 0($2)
	lw $5 0($2)
	bne $5 $3 fail


	.data
sdc1_:	.asciiz "Testing SDC1\n"
	.align 2
sdc1d_:	.word 0, 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sdc1_
	syscall

	li $3, 0x7f7f7f7f
	li $4, 0xf7f7f7f7
	la $2 sdc1d_
	mtc1 $3, $0
	mtc1 $4, $1
	sdc1 $f0 0($2)
	lw $5 0($2)
	bne $5 $3 fail
	lw $5 4($2)
	bne $5 $4 fail


	.data
s.d_:	.asciiz "Testing S.D\n"
	.align 2
s.dd_:	.word 0, 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 s.d_
	syscall

	li $3, 0x7f7f7f7f
	li $4, 0xf7f7f7f7
	la $2 s.dd_
	mtc1 $3, $0
	mtc1 $4, $1
	s.d $f0 0($2)
	lw $5 0($2)
	bne $5 $3 fail
	lw $5 4($2)
	bne $5 $4 fail


# SDC2 not tested

	.data
sll_:	.asciiz "Testing SLL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sll_
	syscall

	li $2 1

	sll $3 $2 0
	bne $3 1 fail
	sll $3 $2 1
	bne $3 2 fail
	sll $3 $2 16
	bne $3 0x10000 fail
	sll $3 $2 31
	bne $3 0x80000000 fail


	.data
sllv_:	.asciiz "Testing SLLV\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sllv_
	syscall

	li $2 1
	li $4 0
	sllv $3 $2 $4
	bne $3 1 fail
	li $4 1
	sllv $3 $2 $4
	bne $3 2 fail
	li $4 16
	sllv $3 $2 $4
	bne $3 0x10000 fail
	li $4 32
	sllv $3 $2 $4
	bne $3 1 fail


	.data
slt_:	.asciiz "Testing SLT\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 slt_
	syscall

	slt $3 $0 $0
	bne $3 0 fail
	li $2 1
	slt $3 $2 $0
	bne $3 0 fail
	slt $3 $0 $2
	bne $3 1 fail
	li $2 -1
	slt $3 $2 $0
	bne $3 1 fail
	slt $3 $0 $2
	bne $3 0 fail
	li $2 -1
	li $4 1
	slt $3 $2 $4
	bne $3 1 fail


	.data
slti_:	.asciiz "Testing SLTI\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 slti_
	syscall

	slti $3 $0 0
	bne $3 0 fail
	li $2 1
	slti $3 $2 0
	bne $3 0 fail
	slti $3 $0 1
	bne $3 1 fail
	li $2 -1
	slti $3 $2 0
	bne $3 1 fail
	slti $3 $0 -1
	bne $3 0 fail
	li $2 -1
	li $4 1
	slti $3 $2 1
	bne $3 1 fail
	slti $3 $4 -1
	bne $3 0 fail


	.data
sltiu_:	.asciiz "Testing SLTIU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sltiu_
	syscall

	sltiu $3 $0 0
	bne $3 0 fail
	li $2 1
	sltiu $3 $2 0
	bne $3 0 fail
	sltiu $3 $0 1
	bne $3 1 fail
	li $2 -1
	sltiu $3 $2 0
	bne $3 0 fail
	sltiu $3 $0 -1
	bne $3 1 fail
	li $2 -1
	li $4 1
	sltiu $3 $2 1
	bne $3 0 fail
	sltiu $3 $4 -1
	bne $3 1 fail


	.data
sltu_:	.asciiz "Testing SLTU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sltu_
	syscall

	sltu $3 $0 $0
	bne $3 0 fail
	li $2 1
	sltu $3 $2 $0
	bne $3 0 fail
	sltu $3 $0 $2
	bne $3 1 fail
	li $2 -1
	sltu $3 $2 $0
	bne $3 0 fail
	sltu $3 $0 $2
	bne $3 1 fail
	li $2 -1
	li $4 1
	sltu $3 $2 $4
	bne $3 0 fail


	.data
sra_:	.asciiz "Testing SRA\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sra_
	syscall

	li $2 1
	sra $3 $2 0
	bne $3 1 fail
	sra $3 $2 1
	bne $3 0 fail
	li $2 0x1000
	sra $3 $2 4
	bne $3 0x100 fail
	li $2 0x80000000
	sra $3 $2 4
	bne $3 0xf8000000 fail


	.data
srav_:	.asciiz "Testing SRAV\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 srav_
	syscall

	li $2 1
	li $4 0
	srav $3 $2 $4
	bne $3 1 fail
	li $4 1
	srav $3 $2 $4
	bne $3 0 fail
	li $2 0x1000
	li $4 4
	srav $3 $2 $4
	bne $3 0x100 fail
	li $2 0x80000000
	li $4 4
	srav $3 $2 $4
	bne $3 0xf8000000 fail


	.data
srl_:	.asciiz "Testing SRL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 srl_
	syscall

	li $2 1
	srl $3 $2 0
	bne $3 1 fail
	srl $3 $2 1
	bne $3 0 fail
	li $2 0x1000
	srl $3 $2 4
	bne $3 0x100 fail
	li $2 0x80000000
	srl $3 $2 4
	bne $3 0x08000000 fail


	.data
srlv_:	.asciiz "Testing SRLV\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 srlv_
	syscall

	li $2 1
	li $4 0
	srlv $3 $2 $4
	bne $3 1 fail
	li $4 1
	srlv $3 $2 $4
	bne $3 0 fail
	li $2 0x1000
	li $4 4
	srlv $3 $2 $4
	bne $3 0x100 fail
	li $2 0x80000000
	li $4 4
	srlv $3 $2 $4
	bne $3 0x08000000 fail


	.data
ssnop_:	.asciiz "Testing SSNOP\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 nop_
	syscall

	ssnop		# How do we test it??


	.data
sub_:	.asciiz "Testing SUB\n"
sub1_:	.asciiz "Expect an overflow exceptions:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sub_
	syscall

	li $2 1
	li $3 -1

	sub $4, $0, $0
	bnez $4 fail
	sub $4, $0, $2
	bne $4 -1 fail
	sub $4, $2, $0
	bne $4, 1 fail
	sub $4, $2, $3
	bne $4, 2 fail
	sub $4, $3, $2
	bne $4, -2 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 sub1_
	syscall
	li $2 0x80000000
	li $3 1
	sub $4, $3, $2


	.data
subu_:	.asciiz "Testing SUBU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 subu_
	syscall

	li $2 1
	li $3 -1

	subu $4, $0, $0
	bnez $4 fail
	subu $4, $0, $2
	bne $4 -1 fail
	subu $4, $2, $0
	bne $4, 1 fail
	subu $4, $2, $3
	bne $4, 2 fail
	subu $4, $3, $2
	bne $4, -2 fail

	li $2 0x80000000
	li $3 1
	subu $4, $3, $2


	.data
sw_:	.asciiz "Testing SW\n"
sw2_:	.asciiz "Expect two address error exceptions:\n"
	.align 2
swd_:	.byte 0, 0, 0, 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sw_
	syscall

	li $3, 0x7f7f7f7f
	la $2 swd_
	sw $3 0($2)
	lw $4 0($2)
	bne $4 0x7f7f7f7f fail

	li $2, 4
	sw $3 swd_($2)
	lw $4 swd_($2)
	bne $4 0x7f7f7f7f fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 sw2_
	syscall

	li $t5 0x7fffffff
	sw $3 1000($t5)
	sw $3 1001($t5)

	lw $t0 far_away
	sw $0 far_away
	lw $t1 far_away
	bne $t1 $0 fail


# SWL is endian-specific


# SWR is endian-specific


	.data
sync_:	.asciiz "Testing SYNC\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 nop_
	syscall

	sync


	.data
syscall_:.asciiz "Testing SYSCALL\n"
syscall1_:.asciiz "The next line should contain: -1, -1.000000, -2.000000\n"
syscall2_:.asciiz ", "
fp_sm1:	.float -1.0
fp_dm2:	.double -2.0
fp_c1:	.float 17.18
fp_c2:	.float 1700.18
fp_c3:	.double 17.18e10
fp_c4:	.double 1700.18e10
syscall5_:.asciiz "\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 syscall_
	syscall

	li $v0 4	# syscall 4 (print_str)
	la $a0 syscall1_
	syscall

	li $v0 1	# syscall 1 (print_int)
	li $a0 -1
	syscall

	li $v0 4	# syscall 4 (print_str)
	la $a0 syscall2_
	syscall

	lwc1 $f12 fp_sm1# syscall 2 (print_float)
	li $v0 2
	syscall

	li $v0 4	# syscall 4 (print_str)
	la $a0 syscall2_
	syscall

	lwc1 $f12 fp_dm2# syscall 3 (print_double)
	lwc1 $f13 fp_dm2+4
	li $v0 3
	syscall

	li $v0 4	# syscall 4 (print_str)
	la $a0 syscall5_
	syscall

	li $v0 5	# syscall 5 (read_int)
	syscall
	bne $v0 17 fail

	li $v0 5	# syscall 5 (read_int)
	syscall
	bne $v0 1717 fail

	li $v0 6	# syscall 6 (read_float)
	syscall
	lwc1 $f2 fp_c1
	c.eq.s $f0, $f2
	bc1f fail

	li $v0 6	# syscall 6 (read_float)
	syscall
	lwc1 $f2 fp_c2
	c.eq.s $f0, $f2
	bc1f fail

	li $v0 7	# syscall 7 (read_double)
	syscall
	lwc1 $f2 fp_c3
	lwc1 $f3 fp_c3+4
	c.eq.d $f0, $f2
	bc1f fail

	li $v0 7	# syscall 7 (read_double)
	syscall
	lwc1 $f2 fp_c4
	lwc1 $f3 fp_c4+4
	c.eq.d $f0, $f2
	bc1f fail


	.data
teq_:	.asciiz "Testing TEQ\nExpect one exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 teq_
	syscall

	li $2 1
	teq $0 $2
	teq $0 $0


	.data
teqi_:	.asciiz "Testing TEQI\nExpect one exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 teqi_
	syscall

	teqi $0 4
	teqi $0 0


	.data
tge_:	.asciiz "Testing TGE\nExpect two exception messages:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tge_
	syscall

	li $2 1
	li $3 2
	tge $2 $3
	tge $0 $0
	tge $3 $2


	.data
tgei_:	.asciiz "Testing TGEI\nExpect two exception messages:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tgei_
	syscall

	li $2 8
	tgei $0 4
	tgei $0 0
	tgei $2 1


	.data
tgeiu_:	.asciiz "Testing TGEIU\nExpect two exception messages:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tgeiu_
	syscall

	li $2 -4
	tgeiu $0 4
	tgeiu $0 0
	tgeiu $2 1


	.data
tgeu_:	.asciiz "Testing TGEU\nExpect two exception messages:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tgeu_
	syscall

	li $2 1
	li $3 -4
	tgeu $2 $3
	tgeu $0 $0
	tgeu $3 $2


	.data
tlb_:	.asciiz "Testing TLB operations:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tlb_
	syscall
	tlbp
	tlbr
	tlbwi
	tlbr


	.data
tlt_:	.asciiz "Testing TLT\nExpect one exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tlt_
	syscall

	li $2 1
	li $3 2
	tlt $2 $3
	tlt $0 $0
	tlt $3 $2


	.data
tlti_:	.asciiz "Testing TLTI\nExpect one exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tlti_
	syscall

	li $2 8
	tlti $0 4
	tlti $0 0
	tlti $2 1


	.data
tltiu_:	.asciiz "Testing TLTIU\nExpect one exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tltiu_
	syscall

	li $2 -4
	tltiu $0 4
	tltiu $0 0
	tltiu $2 1


	.data
tltu_:	.asciiz "Testing TLTU\nExpect one exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tltu_
	syscall

	li $2 1
	li $3 -4
	tltu $2 $3
	tltu $0 $0
	tltu $3 $2


	.data
tne_:	.asciiz "Testing TNE\nExpect one exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tne_
	syscall

	li $2 1
	tne $0 $2
	tne $0 $0


	.data
tnei_:	.asciiz "Testing TNEI\nExpect one exception message:\n  "
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 tnei_
	syscall

	tnei $0 4
	tnei $0 0


	.data
xor_:	.asciiz "Testing XOR\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 xor_
	syscall

	li $2 1
	li $3 -1

	xor $4 $0 $0
	bne $4 0 fail
	xor $4 $3 $3
	bne $4 0 fail
	xor $4 $2 $3
	bne $4 0xfffffffe fail

	.data
xori_:	.asciiz "Testing XORI\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 xori_
	syscall

	li $2 1
	li $3 -1

	xori $4 $0 0
	bne $4 0 fail
	xori $4 $3 0xffff
	bne $4 0xffff0000 fail
	xori $4 $2 0xffff
	bne $4 0x0000fffe fail


#
# Testing Floating Point Ops
#

	.data
abs.s_:.asciiz "Testing ABS.S\n"
fp_s100:.float 100.0
fp_sm100:.float -100.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 abs.s_
	syscall

	lw $4 fp_s100
	lwc1 $f0 fp_s100
	abs.s $f2 $f0
	mfc1 $5 $f2
	bne $4 $5 fail

	lwc1 $f0 fp_sm100
	abs.s $f2 $f0
	mfc1 $5 $f2
	bne $4 $5 fail


	.data
abs.d_:.asciiz "Testing ABS.D\n"
fp_d100:.double 100.0
fp_dm100:.double -100.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 abs.d_
	syscall

	lw $4 fp_d100
	lw $5 fp_d100+4
	lwc1 $f0 fp_d100
	lwc1 $f1 fp_d100+4
	abs.d $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lwc1 $f0 fp_dm100
	lwc1 $f1 fp_dm100+4
	abs.d $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail


	.data
add.s_:	.asciiz "Testing ADD.S\n"
fp_s0:	.float 0.0
fp_s1:	.float 1.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 add.s_
	syscall

	lw $4 fp_s0
	lwc1 $f0 fp_s0
	add.s $f2 $f0 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_s1
	lwc1 $f0 fp_s0
	lwc1 $f2 fp_s1
	add.s $f4 $f0 $f2
	mfc1 $6 $f4
	bne $4 $6 fail

	lw $4 fp_s0
	lwc1 $f0 fp_s1
	lwc1 $f2 fp_sm1
	add.s $f4 $f0 $f2
	mfc1 $6 $f4
	bne $4 $6 fail


	.data
add.d_:	.asciiz "Testing ADD.D\n"
fp_d0:	.double 0.0
fp_d1:	.double 1.0
fp_dm1:	.double -1.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 add.d_
	syscall

	lw $4 fp_d0
	lw $5 fp_d0+4
	lwc1 $f0 fp_d0
	lwc1 $f1 fp_d0+4
	add.d $f2 $f0 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f0 fp_d0
	lwc1 $f1 fp_d0+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	add.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_d0
	lw $5 fp_d0+4
	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_dm1
	lwc1 $f3 fp_dm1+4
	add.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail


	.data
bc1f_:	.asciiz "Testing BC1F and BC1T\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bc1f_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.eq.s $f0 $f2
	bc1f fail
	bc1t l205
	j fail
l205:	c.eq.s $f0 $f4
	bc1t fail
	bc1f l206
	j fail
l206:




# ToDo: Check order/unordered exception in floating point comparison.

	.data
c.eq.d_:	.asciiz "Testing C.EQ.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.eq.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	lwc1 $f4 fp_d1p5
	lwc1 $f5 fp_d1p5+4
	c.eq.d $f0 $f2
	bc1f fail
	bc1t l200
	j fail
l200:	c.eq.d $f0 $f4
	bc1t fail
	bc1f l201
	j fail
l201:


	.data
c.eq.s_:	.asciiz "Testing C.EQ.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.eq.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.eq.s $f0 $f2
	bc1f fail
	bc1t l210
	j fail
l210:	c.eq.s $f0 $f4
	bc1t fail
	bc1f l211
	j fail
l211:


	.data
c.f.d_:	.asciiz "Testing C.F.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.f.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	lwc1 $f4 fp_d1p5
	lwc1 $f5 fp_d1p5+4
	c.f.d $f0 $f2
	bc1t fail
	bc1f l220
	j fail
l220:	c.f.d $f0 $f4
	bc1t fail
	bc1f l221
	j fail
l221:


	.data
c.f.s_:	.asciiz "Testing C.F.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.f.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.f.s $f0 $f2
	bc1t fail
	bc1f l230
	j fail
l230:	c.f.s $f0 $f4
	bc1t fail
	bc1f l231
	j fail
l231:


	.data
c.le.d_:	.asciiz "Testing C.LE.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.le.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1p5
	lwc1 $f3 fp_d1p5+4
	lwc1 $f4 fp_dm2
	lwc1 $f5 fp_dm2+4
	c.le.d $f0 $f2
	bc1f fail
	bc1t l240
	j fail
l240:	c.le.d $f2 $f0
	bc1t fail
	bc1f l241
	j fail
l241:	c.le.d $f0 $f0
	bc1f fail
	bc1t l242
	j fail
l242:	c.le.d $f4 $f0
	bc1f fail
	bc1t l243
	j fail
l243:


	.data
c.le.s_:	.asciiz "Testing C.LE.S\n"
fp_sm2:	.float -2.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.le.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1p5
	lwc1 $f4 fp_sm2
	c.le.s $f0 $f2
	bc1f fail
	bc1t l250
	j fail
l250:	c.le.s $f2 $f0
	bc1t fail
	bc1f l251
	j fail
l251:	c.le.s $f0 $f0
	bc1f fail
	bc1t l252
	j fail
l252:	c.le.s $f4 $f0
	bc1f fail
	bc1t l253
	j fail
l253:


	.data
c.lt.d_:	.asciiz "Testing C.LT.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.lt.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1p5
	lwc1 $f3 fp_d1p5+4
	lwc1 $f4 fp_dm2
	lwc1 $f5 fp_dm2+4
	c.lt.d $f0 $f2
	bc1f fail
	bc1t l260
	j fail
l260:	c.lt.d $f2 $f0
	bc1t fail
	bc1f l261
	j fail
l261:	c.lt.d $f0 $f0
	bc1t fail
	bc1f l262
	j fail
l262:	c.lt.d $f4 $f0
	bc1f fail
	bc1t l263
	j fail
l263:


	.data
c.lt.s_:	.asciiz "Testing C.LT.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.lt.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1p5
	lwc1 $f4 fp_sm2
	c.lt.s $f0 $f2
	bc1f fail
	bc1t l270
	j fail
l270:	c.lt.s $f2 $f0
	bc1t fail
	bc1f l271
	j fail
l271:	c.lt.s $f0 $f0
	bc1t fail
	bc1f l272
	j fail
l272:	c.lt.s $f4 $f0
	bc1f fail
	bc1t l273
	j fail
l273:


	.data
c.nge.d_:	.asciiz "Testing C.NGE.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.nge.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1p5
	lwc1 $f3 fp_d1p5+4
	lwc1 $f4 fp_dm2
	lwc1 $f5 fp_dm2+4
	c.nge.d $f0 $f2
	bc1f fail
	bc1t l280
	j fail
l280:	c.nge.d $f2 $f0
	bc1t fail
	bc1f l281
	j fail
l281:	c.nge.d $f0 $f0
	bc1t fail
	bc1f l282
	j fail
l282:	c.nge.d $f4 $f0
	bc1f fail
	bc1t l283
	j fail
l283:


	.data
c.nge.s_:	.asciiz "Testing C.NGE.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.nge.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1p5
	lwc1 $f4 fp_sm2
	c.nge.s $f0 $f2
	bc1f fail
	bc1t l290
	j fail
l290:	c.nge.s $f2 $f0
	bc1t fail
	bc1f l291
	j fail
l291:	c.nge.s $f0 $f0
	bc1t fail
	bc1f l292
	j fail
l292:	c.nge.s $f4 $f0
	bc1f fail
	bc1t l293
	j fail
l293:


	.data
c.ngle.d_:	.asciiz "Testing C.NGLE.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ngle.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	lwc1 $f4 fp_d1p5
	lwc1 $f5 fp_d1p5+4
	c.ngle.d $f0 $f2
	bc1t fail
l300:	c.ngle.d $f0 $f4
	bc1t fail
l301:


	.data
c.ngle.s_:	.asciiz "Testing C.NGLE.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ngle.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.ngle.s $f0 $f2
	bc1t fail
l310:	c.ngle.s $f0 $f4
	bc1t fail
l311:


	.data
c.ngl.d_:	.asciiz "Testing C.NGL.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ngl.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	lwc1 $f4 fp_d1p5
	lwc1 $f5 fp_d1p5+4
	c.ngl.d $f0 $f2
	bc1f fail
	bc1t l320
	j fail
l320:	c.ngl.d $f0 $f4
	bc1t fail
	bc1f l321
	j fail
l321:


	.data
c.ngl.s_:	.asciiz "Testing C.NGL.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ngl.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.ngl.s $f0 $f2
	bc1f fail
	bc1t l330
	j fail
l330:	c.ngl.s $f0 $f4
	bc1t fail
	bc1f l331
	j fail
l331:


	.data
c.ngt.d_:	.asciiz "Testing C.NGT.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ngt.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1p5
	lwc1 $f3 fp_d1p5+4
	lwc1 $f4 fp_dm2
	lwc1 $f5 fp_dm2+4
	c.ngt.d $f0 $f2
	bc1f fail
	bc1t l340
	j fail
l340:	c.ngt.d $f2 $f0
	bc1t fail
	bc1f l341
	j fail
l341:	c.ngt.d $f0 $f0
	bc1f fail
	bc1t l342
	j fail
l342:	c.ngt.d $f4 $f0
	bc1f fail
	bc1t l343
	j fail
l343:


	.data
c.ngt.s_:	.asciiz "Testing C.NGT.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ngt.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1p5
	lwc1 $f4 fp_sm2
	c.ngt.s $f0 $f2
	bc1f fail
	bc1t l350
	j fail
l350:	c.ngt.s $f2 $f0
	bc1t fail
	bc1f l351
	j fail
l351:	c.ngt.s $f0 $f0
	bc1f fail
	bc1t l352
	j fail
l352:	c.ngt.s $f4 $f0
	bc1f fail
	bc1t l353
	j fail
l353:


	.data
c.ole.d_:	.asciiz "Testing C.OLE.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ole.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1p5
	lwc1 $f3 fp_d1p5+4
	lwc1 $f4 fp_dm2
	lwc1 $f5 fp_dm2+4
	c.ole.d $f0 $f2
	bc1f fail
	bc1t l360
	j fail
l360:	c.ole.d $f2 $f0
	bc1t fail
	bc1f l361
	j fail
l361:	c.ole.d $f0 $f0
	bc1f fail
	bc1t l362
	j fail
l362:	c.ole.d $f4 $f0
	bc1f fail
	bc1t l363
	j fail
l363:


	.data
c.ole.s_:	.asciiz "Testing C.OLE.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ole.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1p5
	lwc1 $f4 fp_sm2
	c.ole.s $f0 $f2
	bc1f fail
	bc1t l370
	j fail
l370:	c.ole.s $f2 $f0
	bc1t fail
	bc1f l371
	j fail
l371:	c.ole.s $f0 $f0
	bc1f fail
	bc1t l372
	j fail
l372:	c.ole.s $f4 $f0
	bc1f fail
	bc1t l373
	j fail
l373:


	.data
c.seq.d_:	.asciiz "Testing C.SEQ.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.seq.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	lwc1 $f4 fp_d1p5
	lwc1 $f5 fp_d1p5+4
	c.seq.d $f0 $f2
	bc1f fail
	bc1t l380
	j fail
l380:	c.seq.d $f0 $f4
	bc1t fail
	bc1f l381
	j fail
l381:


	.data
c.seq.s_:	.asciiz "Testing C.SEQ.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.seq.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.seq.s $f0 $f2
	bc1f fail
	bc1t l390
	j fail
l390:	c.seq.s $f0 $f4
	bc1t fail
	bc1f l391
	j fail
l391:


	.data
c.sf.d_:	.asciiz "Testing C.SF.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.sf.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	lwc1 $f4 fp_d1p5
	lwc1 $f5 fp_d1p5+4
	c.sf.d $f0 $f2
	bc1t fail
l400:	c.sf.d $f0 $f4
	bc1t fail
l401:


	.data
c.sf.s_:	.asciiz "Testing C.SF.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.sf.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.sf.s $f0 $f2
	bc1t fail
l410:	c.sf.s $f0 $f4
	bc1t fail
l411:


	.data
c.ueq.d_:	.asciiz "Testing C.UEQ.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ueq.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	lwc1 $f4 fp_d1p5
	lwc1 $f5 fp_d1p5+4
	c.ueq.d $f0 $f2
	bc1f fail
	bc1t l420
	j fail
l420:	c.ueq.d $f0 $f4
	bc1t fail
	bc1f l421
	j fail
l421:


	.data
c.ueq.s_:	.asciiz "Testing C.UEQ.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ueq.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.ueq.s $f0 $f2
	bc1f fail
	bc1t l430
	j fail
l430:	c.ueq.s $f0 $f4
	bc1t fail
	bc1f l431
	j fail
l431:


	.data
c.ule.d_:	.asciiz "Testing C.ULE.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ule.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1p5
	lwc1 $f3 fp_d1p5+4
	lwc1 $f4 fp_dm2
	lwc1 $f5 fp_dm2+4
	c.ule.d $f0 $f2
	bc1f fail
	bc1t l440
	j fail
l440:	c.ule.d $f2 $f0
	bc1t fail
	bc1f l441
	j fail
l441:	c.ule.d $f0 $f0
	bc1f fail
	bc1t l442
	j fail
l442:	c.ule.d $f4 $f0
	bc1f fail
	bc1t l443
	j fail
l443:


	.data
c.ule.s_:	.asciiz "Testing C.ULE.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.ule.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1p5
	lwc1 $f4 fp_sm2
	c.ule.s $f0 $f2
	bc1f fail
	bc1t l450
	j fail
l450:	c.ule.s $f2 $f0
	bc1t fail
	bc1f l451
	j fail
l451:	c.ule.s $f0 $f0
	bc1f fail
	bc1t l452
	j fail
l452:	c.ule.s $f4 $f0
	bc1f fail
	bc1t l453
	j fail
l453:


	.data
c.un.d_:	.asciiz "Testing C.UN.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.un.d_
	syscall

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	lwc1 $f4 fp_d1p5
	lwc1 $f5 fp_d1p5+4
	c.un.d $f0 $f2
	bc1t fail
	bc1f l460
	j fail
l460:	c.un.d $f0 $f4
	bc1t fail
	bc1f l461
	j fail
l461:


	.data
c.un.s_:	.asciiz "Testing C.UN.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 c.un.s_
	syscall

	lwc1 $f0 fp_s1
	lwc1 $f2 fp_s1
	lwc1 $f4 fp_s1p5
	c.un.s $f0 $f2
	bc1t fail
	bc1f l470
	j fail
l470:	c.un.s $f0 $f4
	bc1t fail
	bc1f l471
	j fail
l471:


# CFC1 and CTC1 tested previously


	.data
ceil.w.d_:	.asciiz "Testing CEIL.W.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ceil.w.d_
	syscall

	lwc1 $f2 fp_d0
	lwc1 $f3 fp_d0+4
	ceil.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 0 fail

	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	ceil.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail

	lwc1 $f2 fp_d1p5
	lwc1 $f3 fp_d1p5+4
	ceil.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 2 fail


	.data
ceil.w.s_:	.asciiz "Testing CEIL.W.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ceil.w.s_
	syscall

	lwc1 $f2 fp_s0
	ceil.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 0 fail

	lwc1 $f2 fp_s1
	ceil.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail

	lwc1 $f2 fp_s1p5
	ceil.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 2 fail


	.data
cvt.d.s_:	.asciiz "Testing CVT.D.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 cvt.d.s_
	syscall

	lw $4 fp_d0
	lw $5 fp_d0+4
	lwc1 $f0 fp_s0
	cvt.d.s $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f0 fp_s1
	cvt.d.s $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_dm1
	lw $5 fp_dm1+4
	lwc1 $f0 fp_sm1
	cvt.d.s $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail


	.data
cvt.d.w_:	.asciiz "Testing CVT.D.W\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 cvt.d.w_
	syscall

	lw $4 fp_d0
	lw $5 fp_d0+4
	mtc1 $0 $0
	cvt.d.w $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_d1
	lw $5 fp_d1+4
	li $t1 1
	mtc1 $t1 $0
	cvt.d.w $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_dm1
	lw $5 fp_dm1+4
	li $t1 -1
	mtc1 $t1 $0
	cvt.d.w $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail


	.data
cvt.s.d_:	.asciiz "Testing CVT.S.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 cvt.s.d_
	syscall

	lw $4 fp_s0
	lwc1 $f0 fp_d0
	lwc1 $f1 fp_d0+4
	cvt.s.d $f2 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_s1
	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	cvt.s.d $f2 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_sm1
	lwc1 $f0 fp_dm1
	lwc1 $f1 fp_dm1+4
	cvt.s.d $f2 $f0
	mfc1 $6 $f2
	bne $4 $6 fail


	.data
cvt.s.w_:	.asciiz "Testing CVT.S.W\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 cvt.s.w_
	syscall

	lw $4 fp_s0
	mtc1 $0 $0
	cvt.s.w $f2 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_s1
	li $t1 1
	mtc1 $t1 $0
	cvt.s.w $f2 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_sm1
	li $t1 -1
	mtc1 $t1 $0
	cvt.s.w $f2 $f0
	mfc1 $6 $f2
	bne $4 $6 fail


	.data
cvt.w.d_:	.asciiz "Testing CVT.W.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 cvt.w.d_
	syscall

	lwc1 $f0 fp_d0
	lwc1 $f1 fp_d0+4
	cvt.w.d $f2 $f0
	mfc1 $6 $f2
	bne $0 $6 fail

	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	cvt.w.d $f2 $f0
	mfc1 $6 $f2
	li $4 1
	bne $4 $6 fail

	lwc1 $f0 fp_dm1
	lwc1 $f1 fp_dm1+4
	cvt.w.d $f2 $f0
	mfc1 $6 $f2
	li $4 -1
	bne $4 $6 fail


	.data
cvt.w.s_:	.asciiz "Testing CVT.W.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 cvt.w.s_
	syscall

	lwc1 $f0 fp_s0
	cvt.w.s $f2 $f0
	mfc1 $6 $f2
	bne $0 $6 fail

	lwc1 $f0 fp_s1
	cvt.w.s $f2 $f0
	mfc1 $6 $f2
	li $4 1
	bne $4 $6 fail

	lwc1 $f0 fp_sm1
	cvt.w.s $f2 $f0
	mfc1 $6 $f2
	li $4 -1
	bne $4 $6 fail


	.data
div.s_:	.asciiz "Testing DIV.S\n"
fp_s2:	.float 2.0
fp_s3:	.float 3.0
fp_s1p5:.float 1.5
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 div.s_
	syscall

	lw $4 fp_s1
	lwc1 $f0 fp_s1
	div.s $f2 $f0 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_s1p5
	lwc1 $f0 fp_s3
	lwc1 $f2 fp_s2
	div.s $f4 $f0 $f2
	mfc1 $6 $f4
	bne $4 $6 fail


	.data
div.d_:	.asciiz "Testing DIV.D\n"
fp_d2:	.double 2.0
fp_d3:	.double 3.0
fp_d1p5:.double 1.5
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 div.d_
	syscall

	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	div.d $f2 $f0 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_d1p5
	lw $5 fp_d1p5+4
	lwc1 $f0 fp_d3
	lwc1 $f1 fp_d3+4
	lwc1 $f2 fp_d2
	lwc1 $f3 fp_d2+4
	div.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail


	.data
floor.w.d_:	.asciiz "Testing FLOOR.W.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 floor.w.d_
	syscall

	lwc1 $f2 fp_d0
	lwc1 $f3 fp_d0+4
	floor.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 0 fail

	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	floor.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail

	lwc1 $f2 fp_d1p5
	lwc1 $f3 fp_d1p5+4
	floor.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail


	.data
floor.w.s_:	.asciiz "Testing FLOOR.W.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 floor.w.s_
	syscall

	lwc1 $f2 fp_s0
	floor.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 0 fail

	lwc1 $f2 fp_s1
	floor.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail

	lwc1 $f2 fp_s1p5
	floor.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail


	.data
ldc1_:	.asciiz "Testing LDC1\n"
	.align 2
ldc1d_:	.word 0x7f7f7f7f, 0xf7f7f7f7
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ldc1_
	syscall

	la $2 ldc1d_
	ldc1 $f0 0($2)
	mfc1 $3, $f0
	mfc1 $4, $f1
	lw $5 0($2)
	bne $5 $3 fail
	lw $5 4($2)
	bne $5 $4 fail


	.data
l.d_:	.asciiz "Testing L.D\n"
	.align 2
l.dd_:	.word 0x7f7f7f7f, 0xf7f7f7f7
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 l.d_
	syscall

	la $2 l.dd_
	l.d $f0 0($2)
	mfc1 $3, $f0
	mfc1 $4, $f1
	lw $5 0($2)
	bne $5 $3 fail
	lw $5 4($2)
	bne $5 $4 fail


	.data
lwc1_:	.asciiz "Testing LWC1\n"
	.align 2
lwc1d_:	.word 0x7f7f7f7f
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lwc1_
	syscall

	la $2 lwc1d_
	lwc1 $f0 0($2)
	mfc1 $3 $f0
	lw $4 0($2)
	bne $4 $3 fail


	.data
l.s_:	.asciiz "Testing L.S\n"
	.align 2
l.sd_:	.word 0x7f7f7f7f
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 l.s_
	syscall

	la $2 l.sd_
	l.s $f0 0($2)
	mfc1 $3 $f0
	lw $4 0($2)
	bne $4 $3 fail


# MFC1 tested previously


	.data
mov.s_:	.asciiz "Testing MOV.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 mov.s_
	syscall

	lw $4 fp_s1
	lwc1 $f2 fp_s1
	mov.s $f4 $f2
	mov.s $f6 $f4
	mfc1 $6 $f6
	bne $4 $6 fail

	.data
mov.d_:	.asciiz "Testing MOV.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 mov.d_
	syscall

	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	mov.d $f4 $f2
	mov.d $f6 $f4
	mfc1 $6 $f6
	mfc1 $7 $f7
	bne $4 $6 fail
	bne $5 $7 fail

	.data
movf.d_:.asciiz "Testing MOVF.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movf.d_
	syscall

	li $2 0xf0
	ctc1 $2 $25

	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	mtc1 $0 $6
	mtc1 $0 $7
	movf.d $f4 $f2 1
	movf.d $f6 $f4 7
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail
	mfc1 $6 $f6
	mfc1 $7 $f7
	bne $6 0 fail
	bne $7 0 fail


	.data
movf.s_:.asciiz "Testing MOVF.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movf.s_
	syscall

	li $2 0xf0
	ctc1 $2 $25

	lw $4 fp_s1
	lwc1 $f2 fp_s1
	mtc1 $0 $6
	mtc1 $0 $7
	movf.s $f4 $f2 1
	movf.s $f6 $f4 7
	mfc1 $6 $f4
	bne $4 $6 fail
	mfc1 $6 $f6
	bne $6 0 fail


	.data
movn.d_:.asciiz "Testing MOVN.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movn.d_
	syscall

	li $2 2
	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	movn.d $f2 $f0 $2
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $6 $4 fail
	bne $7 $5 fail

	lwc1 $f0 fp_d1p5
	lwc1 $f1 fp_d1p5+4
	movn.d $f2 $f0 $0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $6 $4 fail
	bne $7 $5 fail


	.data
movn.s_:.asciiz "Testing MOVN.s\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movn.s_
	syscall

	li $2 2
	lw $4 fp_s1
	lwc1 $f0 fp_s1
	movn.s $f2 $f0 $2
	mfc1 $6 $f2
	bne $6 $4 fail

	lwc1 $f0 fp_s1p5
	movn.s $f2 $f0 $0
	mfc1 $6 $f2
	bne $6 $4 fail


	.data
movt.d_:.asciiz "Testing MOVT.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movt.d_
	syscall

	li $2 0xf
	ctc1 $2 $25

	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	mtc1 $0 $6
	mtc1 $0 $7
	movt.d $f4 $f2 1
	movt.d $f6 $f4 7
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail
	mfc1 $6 $f6
	mfc1 $7 $f7
	bne $6 0 fail
	bne $7 0 fail


	.data
movt.s_:.asciiz "Testing MOVT.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movt.s_
	syscall

	li $2 0xf
	ctc1 $2 $25

	lw $4 fp_s1
	lwc1 $f2 fp_s1
	mtc1 $0 $6
	mtc1 $0 $7
	movt.s $f4 $f2 1
	movt.s $f6 $f4 7
	mfc1 $6 $f4
	bne $4 $6 fail
	mfc1 $6 $f6
	bne $6 0 fail


	.data
movz.d_:.asciiz "Testing MOVZ.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movz.d_
	syscall

	li $2 2
	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	movz.d $f2 $f0 $0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $6 $4 fail
	bne $7 $5 fail

	lwc1 $f0 fp_d1p5
	lwc1 $f1 fp_d1p5+4
	movz.d $f2 $f0 $2
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $6 $4 fail
	bne $7 $5 fail


	.data
movz.s_:.asciiz "Testing MOVZ.s\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 movz.s_
	syscall

	li $2 2
	lw $4 fp_s1
	lwc1 $f0 fp_s1
	movz.s $f2 $f0 $0
	mfc1 $6 $f2
	bne $6 $4 fail

	lwc1 $f0 fp_s1p5
	movz.s $f2 $f0 $2
	mfc1 $6 $f2
	bne $6 $4 fail


# MTC1 tested previously

	.data
mul.s_:	.asciiz "Testing MUL.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 mul.s_
	syscall

	lw $4 fp_s1
	lwc1 $f0 fp_s1
	mul.s $f2 $f0 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_s3
	lwc1 $f0 fp_s1p5
	lwc1 $f2 fp_s2
	mul.s $f4 $f0 $f2
	mfc1 $6 $f4
	bne $4 $6 fail


	.data
mul.d_:	.asciiz "Testing MUL.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 mul.d_
	syscall

	lw $4 fp_d1
	lw $5 fp_d1+4
	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	mul.d $f2 $f0 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_d3
	lw $5 fp_d3+4
	lwc1 $f0 fp_d1p5
	lwc1 $f1 fp_d1p5+4
	lwc1 $f2 fp_d2
	lwc1 $f3 fp_d2+4
	mul.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail


	.data
neg.s_:	.asciiz "Testing NEG.S\n"
fp_sm3:	.float -3.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 neg.s_
	syscall

	lw $4 fp_sm1
	lwc1 $f0 fp_s1
	neg.s $f2 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_s3
	lwc1 $f0 fp_sm3
	neg.s $f2 $f0
	mfc1 $6 $f2
	bne $4 $6 fail


	.data
neg.d_:	.asciiz "Testing NEG.D\n"
fp_dm3:	.double -3.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 neg.d_
	syscall

	lw $4 fp_dm1
	lw $5 fp_dm1+4
	lwc1 $f0 fp_d1
	lwc1 $f1 fp_d1+4
	neg.d $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_d3
	lw $5 fp_d3+4
	lwc1 $f0 fp_dm3
	lwc1 $f1 fp_dm3+4
	neg.d $f4 $f0
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail


	.data
round.w.d_:	.asciiz "Testing ROUND.W.D\n"
fp_d1p6:.double 1.6
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 round.w.d_
	syscall

	lwc1 $f2 fp_d0
	lwc1 $f3 fp_d0+4
	round.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 0 fail

	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	round.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail

	lwc1 $f2 fp_d1p6
	lwc1 $f3 fp_d1p6+4
	round.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 2 fail


	.data
round.w.s_:	.asciiz "Testing ROUND.W.S\n"
fp_s1p6:.float 1.6
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 round.w.s_
	syscall

	lwc1 $f2 fp_s0
	round.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 0 fail

	lwc1 $f2 fp_s1
	round.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail

	lwc1 $f2 fp_s1p6
	round.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 2 fail


	.data
sqrt.d_:.asciiz "Testing SQRT.D\n"
fp_d9:	.double 9.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sqrt.d_
	syscall

	ldc1 $f2 fp_d9
	sqrt.d $f0 $f2
	mul.d $f4 $f0 $f0
	c.eq.d $f2 $f4
	bc1f 0 fail


	.data
sqrt.s_:.asciiz "Testing SQRT.S\n"
fp_s9:	.float 9.0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sqrt.s_
	syscall

	ldc1 $f2 fp_s9
	sqrt.s $f0 $f2
	mul.s $f4 $f0 $f0
	c.eq.s $f2 $f4
	bc1f 0 fail


	.data
sub.s_:	.asciiz "Testing SUB.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sub.s_
	syscall

	lw $4 fp_s0
	lwc1 $f0 fp_s0
	sub.s $f2 $f0 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 fp_sm1
	lw $5 fp_s1
	lwc1 $f0 fp_s0
	lwc1 $f2 fp_s1
	sub.s $f4 $f0 $f2
	mfc1 $6 $f4
	bne $4 $6 fail
	sub.s $f4 $f2 $f0
	mfc1 $6 $f4
	bne $5 $6 fail

	lw $4 fp_s1p5
	lwc1 $f0 fp_s1p5
	lwc1 $f2 fp_s3
	sub.s $f4 $f2 $f0
	mfc1 $6 $f4
	bne $4 $6 fail


	.data
sub.d_:	.asciiz "Testing SUB.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sub.d_
	syscall

	lw $4 fp_d0
	lw $5 fp_d0+4
	lwc1 $f0 fp_d0
	lwc1 $f1 fp_d0+4
	sub.d $f2 $f0 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_dm1
	lw $5 fp_dm1+4
	lwc1 $f0 fp_d0
	lwc1 $f1 fp_d0+4
	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	sub.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail
	lw $4 fp_d1
	lw $5 fp_d1+4
	sub.d $f4 $f2 $f0
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail

	lw $4 fp_d1p5
	lw $5 fp_d1p5+4
	lwc1 $f0 fp_d1p5
	lwc1 $f1 fp_d1p5+4
	lwc1 $f2 fp_d3
	lwc1 $f3 fp_d3+4
	sub.d $f4 $f2 $f0
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	bne $5 $7 fail


	.data
trunc.w.d_:	.asciiz "Testing TRUNC.W.D\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 trunc.w.d_
	syscall

	lwc1 $f2 fp_d0
	lwc1 $f3 fp_d0+4
	trunc.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 0 fail

	lwc1 $f2 fp_d1
	lwc1 $f3 fp_d1+4
	trunc.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail

	lwc1 $f2 fp_d1p6
	lwc1 $f3 fp_d1p6+4
	trunc.w.d $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail


	.data
trunc.w.s_:	.asciiz "Testing TRUNC.W.S\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 trunc.w.s_
	syscall

	lwc1 $f2 fp_s0
	trunc.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 0 fail

	lwc1 $f2 fp_s1
	trunc.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail

	lwc1 $f2 fp_s1p6
	trunc.w.s $f0 $f2
	mfc1 $6 $f0
	bne $6 1 fail


#
# Testing Pseudo Ops
#

	.data
abs_:	.asciiz "Testing ABS\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 abs_
	syscall

	li $2 1
	abs $3 $2
	bne $3 1 fail

	li $2 -1
	abs $2 $2
	bne $2 1 fail

	li $2 0
	abs $2 $2
	bne $2 0 fail


	.data
b_:	.asciiz "Testing B\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 b_
	syscall


	b l101
	b fail
l101:


	.data
bal_:	.asciiz "Testing BAL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bal_
	syscall

	bal l102
l103:	j l104
l102:	la $4 l103
	bne $31 $4 fail
	jr $31
l104:


	.data
beqz_:	.asciiz "Testing BEQZ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 beqz_
	syscall

	beqz $0 l105
	j fail
l105:	li $2 1
	beqz $2 fail


	.data
bge_:	.asciiz "Testing BGE\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bge_
	syscall

	bge $0 $0 l106
	j fail
l106:	li $2 1
	bge $0 $2 fail
	bge $2 $0 l107
	j fail
l107:	li $3 -1
	bge $3 $2 fail
	bge $2 $3 l108
	j fail
l108:

	bge $0 0 l109
	j fail
l109:	li $2 1
	bge $0 1 fail
	bge $2 0 l110
	j fail
l110:	li $3 -1
	bge $3 1 fail
	bge $2 -1 l111
	j fail
l111:


	.data
bgeu_:	.asciiz "Testing BGEU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bgeu_
	syscall

	bgeu $0 $0 l112
	j fail
l112:	li $2 1
	bgeu $0 $2 fail
	bgeu $2 $0 l113
	j fail
l113:	li $3 -1
	bgeu $2 $3 fail
	bgeu $3 $2 l114
	j fail
l114:

	bgeu $0 0 l115
	j fail
l115:	li $2 1
	bgeu $0 1 fail
	bgeu $2 0 l116
	j fail
l116:	li $3 -1
	bgeu $2 -1 fail
	bgeu $3 1 l117
	j fail
l117:


	.data
bgt_:	.asciiz "Testing BGT\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bgt_
	syscall

	bgt $0 $0 fail
l120:	li $2 1
	bgt $0 $2 fail
	bgt $2 $0 l121
	j fail
l121:	li $3 -1
	bgt $3 $2 fail
	bgt $2 $3 l122
	j fail
l122:

	bgt $0 0 fail
l123:	li $2 1
	bgt $0 1 fail
	bgt $2 0 l124
	j fail
l124:	li $3 -1
	bgt $3 1 fail
	bgt $2 -1 l125
	j fail
l125:


	.data
bgtu_:	.asciiz "Testing BGTU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bgtu_
	syscall

	bgtu $0 $0 fail
l132:	li $2 1
	bgtu $0 $2 fail
	bgtu $2 $0 l133
	j fail
l133:	li $3 -1
	bgtu $2 $3 fail
	bgtu $3 $2 l134
	j fail
l134:

	bgtu $0 0 fail
l135:	li $2 1
	bgtu $0 1 fail
	bgtu $2 0 l136
	j fail
l136:	li $3 -1
	bgtu $2 -1 fail
	bgtu $3 1 l137
	j fail
l137:


	.data
ble_:	.asciiz "Testing BLE\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ble_
	syscall

	ble $0 $0 l140
	j fail
l140:	li $2 1
	ble $2 $0 fail
	ble $0 $2 l141
	j fail
l141:	li $3 -1
	ble $2 $3 fail
	ble $3 $2 l142
	j fail
l142:

	ble $0 0 l143
	j fail
l143:	li $2 1
	ble $2 0 fail
	ble $0 1 l144
	j fail
l144:	li $3 -1
	ble $2 -1 fail
	ble $3 1 l145
	j fail
l145:


	.data
bleu_:	.asciiz "Testing BLEU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bleu_
	syscall

	bleu $0 $0 l152
	j fail
l152:	li $2 1
	bleu $2 $0 fail
	bleu $0 $2 l153
	j fail
l153:	li $3 -1
	bleu $3 $2 fail
	bleu $2 $3 l154
	j fail
l154:

	bleu $0 0 l155
	j fail
l155:	li $2 1
	bleu $2 0 fail
	bleu $0 1 l156
	j fail
l156:	li $3 -1
	bleu $3 1 fail
	bleu $2 -1 l157
	j fail
l157:


	.data
blt_:	.asciiz "Testing BLT\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 blt_
	syscall

	blt $0 $0 fail
l160:	li $2 1
	blt $2 $0 fail
	blt $0 $2 l161
	j fail
l161:	li $3 -1
	blt $2 $3 fail
	blt $3 $2 l162
	j fail
l162:

	blt $0 0 fail
l163:	li $2 1
	blt $2 0 fail
	blt $0 1 l164
	j fail
l164:	li $3 -1
	blt $2 -1 fail
	blt $3 1 l165
	j fail
l165:


	.data
bltu_:	.asciiz "Testing BLTU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bltu_
	syscall

	bltu $0 $0 fail
l172:	li $2 1
	bltu $2 $0 fail
	bltu $0 $2 l173
	j fail
l173:	li $3 -1
	bltu $3 $2 fail
	bltu $2 $3 l174
	j fail
l174:

	bltu $0 0 fail
l175:	li $2 1
	bltu $2 0 fail
	bltu $0 1 l176
	j fail
l176:	li $3 -1
	bltu $3 1 fail
	bltu $2 -1 l177
	j fail
l177:


	.data
bnez_:	.asciiz "Testing BNEZ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 bnez_
	syscall

	bnez $0 fail
	li $2 1
	bnez $2 l180
	j fail
l180:


# DIV and DIVU checked previously


# LA better work or nothing above will work


	.data
li_:	.asciiz "Testing LI\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 li_
	syscall

	li $2 0xfffffff
	bne $2 0xfffffff fail
	li $2 0xffffffe
	bne $2 0xffffffe fail
	li $2 0
	bnez $2 fail
	li $2 0x7fffffff
	bne $2 0x7fffffff fail
	li $2 32767
	bne $2 32767 fail
	li $2 32768
	bne $2 32768 fail
	li $2 65535
	bne $2 65535 fail
	li $2 65536
	bne $2 65536 fail


	.data
li.d_:	.asciiz "Testing LI.d\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 li.d_
	syscall

	li.d $f0 1.0
	mfc1 $2, $f0
	mfc1 $3, $f1
	lw $4, fp_d1
	lw $5, fp_d1+4
	bne $2 $4 fail
	bne $3 $5 fail

	li.d $f0 -1.0
	mfc1 $2, $f0
	mfc1 $3, $f1
	lw $4, fp_dm1
	lw $5, fp_dm1+4
	bne $2 $4 fail
	bne $3 $5 fail


	.data
li.s_:	.asciiz "Testing LI.s\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 li.s_
	syscall

	li.s $f0 1.0
	mfc1 $2, $f0
	lw $3, fp_s1
	bne $2 $3 fail

	li.s $f0 -1.0
	mfc1 $2, $f0
	lw $3, fp_sm1
	bne $2 $3 fail


	.data
move_:	.asciiz "Testing MOVE\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 move_
	syscall

	li $2 0xfffffff
	move $3 $2
	bne $2 $3 fail


# MUL and MULO and MULOU were tested previously


	.data
neg_:	.asciiz "Testing NEG\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 neg_
	syscall

	li $2 -101
	neg $3 $2
	bne $3 101 fail
	li $2 101
	neg $2 $2
	bne $2 -101 fail
	neg $2 $0
	bne $2 0 fail


	.data
negu_:	.asciiz "Testing NEGU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 negu_
	syscall

	li $2 -101
	negu $3 $2
	bne $3 101 fail
	li $2 101
	negu $2 $2
	bne $2 -101 fail
	negu $2 $0
	bne $2 0 fail


	.data
nop_:	.asciiz "Testing NOP\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 nop_
	syscall

	nop		# How do we test it??


	.data
not_:	.asciiz "Testing NOT\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 not_
	syscall

	not $2 $0
	bne $2 0xffffffff fail
	li $2 0
	not $3 $2
	bne $3 0xffffffff fail
	li $2 0xffffffff
	not $3 $2
	bne $3 0 fail


	.data
rem_:	.asciiz "Testing REM\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 rem_
	syscall

	li $2 5
	li $3 2
	li $4 -2

	rem $5 $2 $3
	bne $5 1 fail

	rem $5 $2 $4
	bne $5 1 fail

	.data
remu_:	.asciiz "Testing REMU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 remu_
	syscall

	li $2 5
	li $3 2
	li $4 -2

	remu $5 $2 $3
	bne $5 1 fail

	remu $5 $2 $4
	bne $5 5 fail


	.data
rol_:	.asciiz "Testing ROL\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 rol_
	syscall
	li $2 5
	li $3 5
	rol $4 $2 $3
	bne $4 0xa0 fail
	li $2 5
	li $3 -5
	rol $4 $2 $3
	bne $4 0x28000000 fail
	li $2 5
	rol $4 $2 5
	bne $4 0xa0 fail


	.data
ror_:	.asciiz "Testing ROR\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ror_
	syscall
	li $2 5
	li $3 5
	ror $4 $2 $3
	bne $4 0x28000000 fail
	li $2 5
	li $3 -5
	ror $4 $2 $3
	bne $4 0xa0 fail
	li $2 5
	ror $4 $2 5
	bne $4 0x28000000 fail


	.data
seq_:	.asciiz "Testing SEQ\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 seq_
	syscall

	li $2 -1
	li $3 1

	seq $4 $0 $0
	beqz $4 fail
	seq $4 $2 $3
	bnez $4 fail

	seq $4 $0 0
	beqz $4 fail
	seq $4 $3 2
	bnez $4 fail


	.data
sge_:	.asciiz "Testing SGE\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sge_
	syscall

	sge $4 $0 $0
	beqz $4 fail
	li $2 1
	sge $4 $0 $2
	bnez $4 fail
	sge $4 $2 $0
	beqz $4 fail
	li $2 -1
	sge $4 $0 $2
	beqz $4 fail
	sge $4 $2 $0
	bnez $4 fail

	li $2 1
	sge $2 $0 $2
	bnez $2 fail
	li $2 1
	sge $2 $2 $0
	beqz $2 fail
	li $2 -1
	sge $2 $0 $2
	beqz $2 fail
	li $2 -1
	sge $2 $2 $0
	bnez $2 fail

	sge $4 $0 0
	beqz $4 fail
	li $2 1
	sge $4 $0 1
	bnez $4 fail
	sge $4 $2 0
	beqz $4 fail
	li $2 -1
	sge $4 $0 -1
	beqz $4 fail
	sge $4 $2 0
	bnez $4 fail


	.data
sgeu_:	.asciiz "Testing SGEU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sgeu_
	syscall

	sgeu $4 $0 $0
	beqz $4 fail
	li $2 1
	sgeu $4 $0 $2
	bnez $4 fail
	sgeu $4 $2 $0
	beqz $4 fail
	li $2 -1
	sgeu $4 $0 $2
	bnez $4 fail
	sgeu $4 $2 $0
	beqz $4 fail

	sgeu $4 $0 0
	beqz $4 fail
	li $2 1
	sgeu $4 $0 1
	bnez $4 fail
	sgeu $4 $2 0
	beqz $4 fail
	li $2 -1
	sgeu $4 $0 -1
	bnez $4 fail
	sgeu $4 $2 0
	beqz $4 fail


	.data
sgt_:	.asciiz "Testing SGT\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sgt_
	syscall

	sgt $4 $0 $0
	bnez $4 fail
	li $2 1
	sgt $4 $0 $2
	bnez $4 fail
	sgt $4 $2 $0
	beqz $4 fail
	li $2 -1
	sgt $4 $0 $2
	beqz $4 fail
	sgt $4 $2 $0
	bnez $4 fail

	sgt $4 $0 0
	bnez $4 fail
	sgt $4 $0 1
	bnez $4 fail
	li $2 1
	sgt $4 $2 0
	beqz $4 fail
	sgt $4 $0 -1
	beqz $4 fail
	li $2 -1
	sgt $4 $2 0
	bnez $4 fail

	.data
sgtu_:	.asciiz "Testing SGTU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sgtu_
	syscall

	sgtu $4 $0 $0
	bnez $4 fail
	li $2 1
	sgtu $4 $0 $2
	bnez $4 fail
	sgtu $4 $2 $0
	beqz $4 fail
	li $2 -1
	sgtu $4 $0 $2
	bnez $4 fail
	sgtu $4 $2 $0
	beqz $4 fail

	sgtu $4 $0 0
	bnez $4 fail
	sgtu $4 $0 1
	bnez $4 fail
	li $2 1
	sgtu $4 $2 0
	beqz $4 fail
	sgtu $4 $0 -1
	bnez $4 fail
	li $2 -1
	sgtu $4 $2 0
	beqz $4 fail


	.data
sle_:	.asciiz "Testing SLE\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sle_
	syscall

	sle $4 $0 $0
	beqz $4 fail
	li $2 1
	sle $4 $0 $2
	beqz $4 fail
	sle $4 $2 $0
	bnez $4 fail
	li $2 -1
	sle $4 $0 $2
	bnez $4 fail
	sle $4 $2 $0
	beqz $4 fail

	li $2 1
	sle $2 $0 $2
	beqz $2 fail
	li $2 1
	sle $2 $2 $0
	bnez $2 fail
	li $2 -1
	sle $2 $0 $2
	bnez $2 fail
	li $2 -1
	sle $2 $2 $0
	beqz $2 fail

	sle $4 $0 0
	beqz $4 fail
	li $2 1
	sle $4 $0 1
	beqz $4 fail
	sle $4 $2 0
	bnez $4 fail
	li $2 -1
	sle $4 $0 -1
	bnez $4 fail
	sle $4 $2 0
	beqz $4 fail


	.data
sleu_:	.asciiz "Testing SLEU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sleu_
	syscall

	sleu $4 $0 $0
	beqz $4 fail
	li $2 1
	sleu $4 $0 $2
	beqz $4 fail
	sleu $4 $2 $0
	bnez $4 fail
	li $2 -1
	sleu $4 $0 $2
	beqz $4 fail
	sleu $4 $2 $0
	bnez $4 fail

	sleu $4 $0 0
	beqz $4 fail
	li $2 1
	sleu $4 $0 1
	beqz $4 fail
	sleu $4 $2 0
	bnez $4 fail
	li $2 -1
	sleu $4 $0 -1
	beqz $4 fail
	sleu $4 $2 0
	bnez $4 fail


	.data
sne_:	.asciiz "Testing SNE\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sne_
	syscall

	li $2 -1
	li $3 1

	sne $4 $0 $0
	bnez $4 fail
	sne $4 $2 $3
	beqz $4 fail

	sne $4 $0 0
	bnez $4 fail
	sne $4 $3 2
	beqz $4 fail


# ULH is endian-specific


# ULHU is endian-specific


# ULW is endian-specific


# USH is endian-specific


# USW is endian-specific


# .WORD is endian-specific


OK:


# Done !!!
	.data
sm:	.asciiz "\nPassed all tests\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sm
	syscall
	lw $31 saved_ret_pc
	jr $31		# Return from main


	.data
fm:	.asciiz "Failed test\n"
	.text
fail:	li $v0 4	# syscall 4 (print_str)
	la $a0 fm
	syscall
	li $v0, 10	# syscall 10 (exit)
	syscall


	.text 0x408000
far_away:
	beq $0, $0, come_back
