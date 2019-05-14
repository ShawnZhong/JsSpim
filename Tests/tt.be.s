# SPIM S20 MIPS simulator.
# A torture test for the SPIM simulator.
# Tests for big-endian systems.
# Run in conjunction with tt.core.s
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
m5:	.asciiz "Expect an address error exception:\n	"
m6:	.asciiz "Expect two address error exceptions:\n"
	.text
	.globl main

main:
	sw $31 saved_ret_pc

	.data
lb_:	.asciiz "Testing LB\n"
lbd_:	.byte 1, -1, 0, 128
lbd1_:	.word 0x76543210, 0xfedcba98
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lb_
	syscall

	la $2 lbd_
	lb $3 0($2)
	bne $3 1 fail
	lb $3 1($2)
	bne $3 -1 fail
	lb $3 2($2)
	bne $3 0 fail
	lb $3 3($2)
	bne $3 0xffffff80 fail

	la $t0 lbd1_
	lb $t1 0($t0)
	bne $t1 0x76 fail
	lb $t1 1($t0)
	bne $t1 0x54 fail
	lb $t1 2($t0)
	bne $t1 0x32 fail
	lb $t1 3($t0)
	bne $t1 0x10 fail
	lb $t1 4($t0)
	bne $t1 0xfffffffe fail
	lb $t1 5($t0)
	bne $t1 0xffffffdc fail
	lb $t1 6($t0)
	bne $t1 0xffffffba fail
	lb $t1 7($t0)
	bne $t1 0xffffff98 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 m5
	syscall

	li $t5 0x7fffffff
	lb $3 1000($t5)


	.data
lbu_:	.asciiz "Testing LBU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lbu_
	syscall

	la $2 lbd_
	lbu $3 0($2)
	bne $3 1 fail
	lbu $3 1($2)
	bne $3 0xff fail
	lbu $3 2($2)
	bne $3 0 fail
	lbu $3 3($2)
	bne $3 128 fail

	la $t0 lbd1_
	lbu $t1 0($t0)
	bne $t1 0x76 fail
	lbu $t1 1($t0)
	bne $t1 0x54 fail
	lbu $t1 2($t0)
	bne $t1 0x32 fail
	lbu $t1 3($t0)
	bne $t1 0x10 fail
	lbu $t1 4($t0)
	bne $t1 0xfe fail
	lbu $t1 5($t0)
	bne $t1 0xdc fail
	lbu $t1 6($t0)
	bne $t1 0xba fail
	lbu $t1 7($t0)
	bne $t1 0x98 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 m5
	syscall

	li $t5 0x7fffffff
	lbu $3 1000($t5)


	.data
lwl_:	.asciiz "Testing LWL\n"
	.align 2
lwld_:	.byte 0 1 2 3 4 5 6 7
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lwl_
	syscall

	la $2 lwld_
	move $3 $0
	lwl $3 0($2)
	bne $3 0x10203 fail
	move $3 $0
	lwl $3 1($2)
	bne $3 0x1020300 fail
	li $3 5
	lwl $3 1($2)
	bne $3 0x1020305 fail
	move $3 $0
	lwl $3 2($2)
	bne $3 0x2030000 fail
	li $3 5
	lwl $3 2($2)
	bne $3 0x2030005 fail
	move $3 $0
	lwl $3 3($2)
	bne $3 0x3000000 fail
	li $3 5
	lwl $3 3($2)
	bne $3 0x3000005 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 m6
	syscall

	li $t5 0x7fffffff
	lwl $3 1000($t5)
	lwl $3 1001($t5)


	.data
lwr_:	.asciiz "Testing LWR\n"
	.align 2
lwrd_:	.byte 0 1 2 3 4 5 6 7
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 lwr_
	syscall

	la $2 lwrd_
	li $3 0x0505
	lwr $3 0($2)
	bne $3 0x0500 fail
	move $3 $0
	lwr $3 1($2)
	bne $3 0x01 fail
	li $3 0x505
	lwr $3 1($2)
	bne $3 0x01 fail
	move $3 $0
	lwr $3 2($2)
	bne $3 0x0102 fail
	li $3 0x050505
	lwr $3 2($2)
	bne $3 0x0102 fail
	move $3 $0
	lwr $3 3($2)
	bne $3 0x010203 fail
	li $3 0x05050505
	lwr $3 3($2)
	bne $3 0x010203 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 m6
	syscall

	li $t5 0x7fffffff
	lwr $3 1000($t5)
	lwr $3 1001($t5)


	.data
sb_:	.asciiz "Testing SB\n"
	.align 2
sbd_:	.byte 0, 0, 0, 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sb_
	syscall

	li $3, 1
	la $2 sbd_
	sb $3 0($2)
	lw $4 0($2)
	bne $4 0x1000000 fail
	li $3 2
	sb $3 1($2)
	lw $4 0($2)
	bne $4 0x1020000 fail
	li $3 3
	sb $3 2($2)
	lw $4 0($2)
	bne $4 0x1020300 fail
	li $3 4
	sb $3 3($2)
	lw $4 0($2)
	bne $4 0x1020304 fail


	li $v0 4	# syscall 4 (print_str)
	la $a0 m5
	syscall

	li $t5 0x7fffffff
	sb $3 1000($t5)


	.data
sh_:	.asciiz "Testing SH\n"
sh2_:	.asciiz "Expect two address error exceptions:\n"
	.align 2
shd_:	.byte 0, 0, 0, 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 sh_
	syscall

	li $3, 1
	la $2 shd_
	sh $3 0($2)
	lw $4 0($2)
	bne $4 0x10000 fail
	li $3 2
	sh $3 2($2)
	lw $4 0($2)
	bne $4 0x10002 fail

	li $v0 4	# syscall 4 (print_str)
	la $a0 sh2_
	syscall

	li $t5 0x7fffffff
	sh $3 1000($t5)
	sh $3 1001($t5)


	.data
swl_:	.asciiz "Testing SWL\n"
	.align 2
swld_:	.word 0 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 swl_
	syscall

	la $2 swld_

	li $3 0x01020304
	swl $3 0($2)
	lw $4 0($2)
	bne $4 0x01020304 fail

	li $3 0x01020300
	swl $3 1($2)
	lw $4 0($2)
	bne $4 0x1010203 fail

	li $3 0x01020000
	swl $3 2($2)
	lw $4 0($2)
	bne $4 0x1010102 fail

	li $3 0x01000000
	swl $3 3($2)
	lw $4 0($2)
	bne $4 0x1010101 fail


	.data
swr_:	.asciiz "Testing SWR\n"
	.align 2
swrd_:	.word 0 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 swr_
	syscall

	la $2 swrd_

	li $3 0x01020304
	swr $3 0($2)
	lw $4 0($2)
	bne $4 0x4000000 fail

	li $3 0x01020304
	swr $3 1($2)
	lw $4 0($2)
	bne $4 0x3040000 fail

	li $3 0x01020304
	swr $3 2($2)
	lw $4 0($2)
	bne $4 0x2030400 fail

	li $3 0x01020304
	swr $3 3($2)
	lw $4 0($2)
	bne $4 0x1020304 fail



	.data
ulh_:	.asciiz "Testing ULH\n"
ulh1_:	.byte 1 2 3 4 5 6 7 8
ulh2_:	.byte 0xff 0xff
	.text

	li $v0 4	# syscall 4 (print_str)
	la $a0 ulh_
	syscall
	la $2 ulh1_
	ulh $3 0($2)
	bne $3 0x0102 fail
	ulh $3 1($2)
	bne $3 0x0203 fail
	ulh $3 2($2)
	bne $3 0x0304 fail
	ulh $3 3($2)
	bne $3 0x0405 fail
	ulh $3 4($2)
	bne $3 0x0506 fail
	la $2 ulh2_
	ulh $3 0($2)
	bne $3 -1 fail


	.data
ulhu_:	.asciiz "Testing ULHU\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ulhu_
	syscall

	li $v0 4	# syscall 4 (print_str)
	la $a0 ulhu_
	syscall
	la $2 ulh1_
	ulhu $3 0($2)
	bne $3 0x0102 fail
	ulhu $3 1($2)
	bne $3 0x0203 fail
	ulhu $3 2($2)
	bne $3 0x0304 fail
	ulhu $3 3($2)
	bne $3 0x0405 fail
	ulhu $3 4($2)
	bne $3 0x0506 fail
	la $2 ulh2_
	ulhu $3 0($2)
	bne $3 0xffff fail


	.data
ulw_:	.asciiz "Testing ULW\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ulw_
	syscall

	la $2 ulh1_
	ulw $3 0($2)
	bne $3 0x1020304 fail
	ulw $3 1($2)
	bne $3 0x2030405 fail
	ulw $3 2($2)
	bne $3 0x3040506 fail
	ulw $3 3($2)
	bne $3 0x4050607 fail


	.data
ush_:	.asciiz "Testing USH\n"
ushd:	.word 0 0
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 ush_
	syscall

	la $2 ushd
	sw $0 0($2)
	sw $0 4($2)
	li $3 -1
	ush $3 0($2)
	lw $4 0($2)
	bne $4 0xffff0000 fail
	lw $4 4($2)
	bne $4 0 fail

	sw $0 0($2)
	sw $0 4($2)
	li $3 -1
	ush $3 1($2)
	lw $4 0($2)
	bne $4 0xffff00 fail
	lw $4 4($2)
	bne $4 0 fail

	sw $0 0($2)
	sw $0 4($2)
	li $3 -1
	ush $3 2($2)
	lw $4 0($2)
	bne $4 0xffff fail
	lw $4 4($2)
	bne $4 0 fail

	sw $0 0($2)
	sw $0 4($2)
	li $3 -1
	ush $3 3($2)
	lw $4 0($2)
	bne $4 0xff fail
	lw $4 4($2)
	bne $4 0xff000000 fail


	.data
usw_:	.asciiz "Testing USW\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 usw_
	syscall

	la $2 ushd
	sw $0 0($2)
	sw $0 4($2)
	li $3 -1
	usw $3 0($2)
	lw $4 0($2)
	bne $4 -1 fail
	lw $4 4($2)
	bne $4 0 fail

	sw $0 0($2)
	sw $0 4($2)
	li $3 -1
	usw $3 1($2)
	lw $4 0($2)
	bne $4 0xffffff fail
	lw $4 4($2)
	bne $4 0xff000000 fail

	sw $0 0($2)
	sw $0 4($2)
	li $3 -1
	usw $3 2($2)
	lw $4 0($2)
	bne $4 0xffff fail
	lw $4 4($2)
	bne $4 0xffff0000 fail

	sw $0 0($2)
	sw $0 4($2)
	li $3 -1
	usw $3 3($2)
	lw $4 0($2)
	bne $4 0xff fail
	lw $4 4($2)
	bne $4 0xffffff00 fail

	.data
word_:	.asciiz "Testing .WORD\n"
	.text
	li $v0 4	# syscall 4 (print_str)
	la $a0 word_
	syscall

	.data
	.align 0
wordd:	.byte 0x1
	.word 0x87654320
	.word 0xfedcba90
	.text
	la $2 wordd
	lwr $3 1($2)
	lwl $3 0($2)
	bne $3 0x01876543 fail
	lwr $3 5($2)
	lwl $3 4($2)
	bne $3 0x20fedcba fail

	.data
	.byte 0
x:	.word OK	# Forward reference in unaligned data!
	.text
	lw $8 x
	beq $8 $0 fail
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

