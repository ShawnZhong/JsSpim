# SPIM S20 MIPS simulator.
# A torture test for the FPU instructions in the bare SPIM simulator.
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


# Adapted by Anne Rogers <amr@blueline.Princeton.EDU> from tt.le.s.
# Run -bare -notrap.


# Test floating point instructions.  Warning: This code is not relocatable.
# New data statements should be added after "Testing C.UN.S\n".

	.data
saved_ret_pc:	.word 0		# Holds PC to return from main
sm:      .asciiz "Failed  "
pt:      .asciiz "Passed all tests\n"

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


	.data
abs.s_:.asciiz "Testing ABS.S\n"
fp_s100:.float 100.0
fp_sm100:.float -100.0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 abs.s_
	lui $a0, 0x1000
	ori $a0 $a0 0x1f
	syscall

        lui $2 0x1000
	ori $2 $2 0x30
	lwc1 $f0 0($2)
	addu $0 $0 $0
	lw $4 0($2)
	addu $0 $0 $0
	mfc1 $5 $f0
	addu $0 $0 $0
	bne $5 $4 fail
	addu $0 $0 $0
	abs.s $f2 $f0
	mfc1 $5 $f2
	addu $0 $0 $0              #Nop
	bne $4 $5 fail

	lwc1 $f0 4($2)
	abs.s $f2 $f0
	mfc1 $5 $f2
	addu $0 $0 $0              #Nop
	bne $4 $5 fail
	addu $0 $0 $0              #Nop

	.data
abs.d_:.asciiz "Testing ABS.D\n"
fp_d100:.double 100.0
fp_dm100:.double -100.0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 abs.d_
	lui $a0, 0x1000
	ori $a0 $a0 0x38
	syscall

#	la $2 fp_d100
	lui $2, 0x1000
	ori $2 $2 0x48
	lw $4 0($2)
	lw $5 4($2)
	lwc1 $f0 0($2)
	lwc1 $f1 4($2)
	addu $0 $0 $0              #Nop
	abs.d $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0              #Nop
	bne $4 $6 fail
	addu $0 $0 $0              #Nop
	bne $5 $7 fail

	lwc1 $f0 8($2)
	lwc1 $f1 12($2)
	addu $0 $0 $0              #Nop
	abs.d $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0              #Nop
	bne $4 $6 fail
	addu $0 $0 $0              #Nop
	bne $5 $7 fail


	.data
add.s_:	.asciiz "Testing ADD.S\n"
fp_s0:	.float 0.0
fp_s1:	.float 1.0
fp_sm1:	.float -1.0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 add.s_
	lui $a0 0x1000
	ori $a0 $a0 0x58
	syscall

	lui $2, 0x1000
	ori $2 $2 0x68
	lw $4 0($2)
	lwc1 $f0 0($2)
	addu $0 $0 $0                  # Nop
	add.s $f2 $f0 $f0
	mfc1 $6 $f2
	addu $0 $0 $0                  # Nop
	bne $4 $6 fail
	addu $0 $0 $0                  # Nop

	lw $4 4($2)
	lwc1 $f0 0($2)
	lwc1 $f2 4($2)
	addu $0 $0 $0                  # Nop
	add.s $f4 $f0 $f2
	mfc1 $6 $f4
	addu $0 $0 $0                  # Nop
	bne $4 $6 fail

	lw $4 0($2)
	lwc1 $f0 4($2)
	lwc1 $f2 8($2)
	addu $0 $0 $0                  # Nop
	add.s $f4 $f0 $f2
	mfc1 $6 $f4
	addu $0 $0 $0                  # Nop
	bne $4 $6 fail

	.data
add.d_:	.asciiz "Testing ADD.D\n"
fp_d0:	.double 0.0
fp_d1:	.double 1.0
fp_dm1:	.double -1.0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 add.d_
	lui $a0 0x1000
	ori $a0 $a0 0x74
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lw $4 0($1)
	lw $5 4($1)
	lwc1 $f0 0($1)
	lwc1 $f1 4($1)
	addu $0 $0 $0              # Nop
	add.d $f2 $f0 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0              # Nop
	bne $4 $6 fail
	addu $0 $0 $0              # Nop
	bne $5 $7 fail

	lw $4 8($1)
	lw $5 12($1)
	lwc1 $f0 0($1)
	lwc1 $f1 4($1)
	lwc1 $f2 8($1)
	lwc1 $f3 12($1)
	addu $0 $0 $0              # Nop
	add.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	addu $0 $0 $0              # Nop
	bne $4 $6 fail
	addu $0 $0 $0              # Nop
	bne $5 $7 fail

	lw $4 0($1)
	lw $5 4($1)
	lwc1 $f0 8($1)
	lwc1 $f1 12($1)
	lwc1 $f2 16($1)
	lwc1 $f3 20($1)
	addu $0 $0 $0              # Nop
	add.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	addu $0 $0 $0              # Nop
	bne $4 $6 fail
	addu $0 $0 $0              # Nop
	bne $5 $7 fail
	addu $0 $0 $0              # Nop

	.data
cvt.d.s_:	.asciiz "Testing CVT.D.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 cvt.d.s_
	lui $a0 0x1000
	ori $a0 $a0 0xa0
	syscall


	lui $1 0x1000
	ori $1 $1 0x88
	lw $4 0($1)                                #fp_d0
	lw $5 4($1)                                #fp_d0+4
	lui $2, 0x1000
	ori $2 $2 0x68
	lwc1 $f0 0($2)                             #fp_s0
	addu $0 $0 $0                              # Nop
	cvt.d.s $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0                              # Nop
	bne $4 $6 fail
	addu $0 $0 $0                              # Nop
	bne $5 $7 fail
	addu $0 $0 $0                              # Nop

	lw $4 8($1)                                # fp_d1
	lw $5 12($1)                               # fp_d1+4
	lwc1 $f0 4($2)                             # fp_s1
	addu $0 $0 $0                              # Nop
	cvt.d.s $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0                              # Nop
	bne $4 $6 fail
	addu $0 $0 $0                              # Nop
	bne $5 $7 fail
	addu $0 $0 $0                              # Nop

	lw $4 16($1)                               # fp_dm1
	lw $5 20($1)                               # fp_dm1+4
	lwc1 $f0 8($2)                             # fp_sm1
	addu $0 $0 $0                              # Nop
	cvt.d.s $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0                              # Nop
	bne $4 $6 fail
	addu $0 $0 $0                              # Nop
	bne $5 $7 fail
	addu $0 $0 $0                              # Nop

	.data
cvt.d.w_:	.asciiz "Testing CVT.D.W\n"
	.text
	addi $v0 $0 4	             # syscall 4 (print_str)
#	la $a0 cvt.d.w_
	lui $a0 0x1000
	ori $a0 $a0 0xb1
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lw $4 0($1)                       # fp_d0
	lw $5 4($1)                       # fp_d0+4
	mtc1 $0 $0
	addu $0 $0 $0                     # Nop
	cvt.d.w $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0                     # Nop
	bne $4 $6 fail
	addu $0 $0 $0                     # Nop
	bne $5 $7 fail
	addu $0 $0 $0                     # Nop

	lw $4 8($1)                       # fp_d1
	lw $5 12 ($1)                     # fp_d1+4
	addi $9 $0 1
	mtc1 $9 $0
	addu $0 $0 $0                     # Nop
	cvt.d.w $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0                     # Nop
	bne $4 $6 fail
	addu $0 $0 $0                     # Nop
	bne $5 $7 fail
	addu $0 $0 $0                     # Nop

	lw $4 16($1)                      # fp_dm1
	lw $5 20($1)                      # fp_dm1+4
	addi $9 $0 -1
	mtc1 $9 $0
	addu $0 $0 $0                     # Nop
	cvt.d.w $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	addu $0 $0 $0                     # Nop
	bne $5 $7 fail
	addu $0 $0 $0                     # Nop

	.data
cvt.s.d_:	.asciiz "Testing CVT.S.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 cvt.s.d_
	lui $a0 0x1000
	ori $a0 $a0 0xc2
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lw $4 0($1)                           # fp_s0
	lui $2 0x1000
	ori $2 $2 0x88
	lwc1 $f0 0($2)                        # fp_d0
	lwc1 $f1 4($2)                        # fp_d0+4
	addu $0 $0 $0              #Nop
	cvt.s.d $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0
	bne $4 $6 fail
	addu $0 $0 $0

	lw $4 4($1)                           # fp_s1
	lwc1 $f0 8($2)                        # fp_d1
	lwc1 $f1 12($2)                       # fp_d1+4
	addu $0 $0 $0              #Nop
	cvt.s.d $f2 $f0
	addu $0 $0 $0
	mfc1 $6 $f2
	addu $0 $0 $0
	bne $4 $6 fail
	addu $0 $0 $0

	lw $4 8($1)                           # fp_sm1
	lwc1 $f0 16($2)                       # fp_dm1
	lwc1 $f1 20 ($2)                      # fp_dm1+4
	addu $0 $0 $0              #Nop
	cvt.s.d $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0
	bne $4 $6 fail
	addu $0 $0 $0


	.data
cvt.s.w_:	.asciiz "Testing CVT.S.W\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 cvt.s.w_
	lui $a0 0x1000
	ori $a0 $a0 0xd3
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lw $4 0($1)                        # fp_s0
	mtc1 $0 $0
	cvt.s.w $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0
	bne $4 $6 fail
	addu $0 $0 $0

	lw $4 4($1)                        # fp_s1
	addi $9 $0 1
	mtc1 $9 $0
	cvt.s.w $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0
	bne $4 $6 fail
	addu $0 $0 $0

	lw $4 8($1)                         # fp_sm1
	addi $9 $0 -1
	mtc1 $9 $0
	cvt.s.w $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0
	bne $4 $6 fail
	addu $0 $0 $0


	.data
cvt.w.d_:	.asciiz "Testing CVT.W.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 cvt.w.d_
	lui $a0 0x1000
	ori $a0 $a0 0xe4
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lwc1 $f0 0($1)                            # fp_d0
	lwc1 $f1 4($1)                            # fp_d0+4
	addu $0 $0 $0                             # Nop
	cvt.w.d $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0                             # Nop
	bne $0 $6 fail
	addu $0 $0 $0                             # Nop

	lwc1 $f0 8($1)                            # fp_d1
	lwc1 $f1 12($1)                           # fp_d1+4
	addu $0 $0 $0                             # Nop
	cvt.w.d $f2 $f0
	mfc1 $6 $f2
	addi $4 $0 1
	addu $0 $0 $0                             # Nop
	bne $4 $6 fail
	addu $0 $0 $0                             # Nop

	lwc1 $f0 16($1)                           # fp_dm1
	lwc1 $f1 20($1)                           # fp_dm1+4
	addu $0 $0 $0              #Nop
	cvt.w.d $f2 $f0
	mfc1 $6 $f2
	addi $4 $0 -1
	bne $4 $6 fail
	addu $0 $0 $0                             # Nop


	.data
cvt.w.s_:	.asciiz "Testing CVT.W.S\n"
	.text
#	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 cvt.w.s_
	lui $a0 0x1000
	ori $a0 $a0 0xf5
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lwc1 $f0 0($1)                             # fp_s0
	addu $0 $0 $0              #Nop
	cvt.w.s $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0                              # Nop
	bne $0 $6 fail
	addu $0 $0 $0                              # Nop

	lwc1 $f0 4($1)                             # fp_s1
	addu $0 $0 $0              #Nop
	cvt.w.s $f2 $f0
	mfc1 $6 $f2
	addi $4 $0 1
	bne $4 $6 fail
	addu $0 $0 $0                              # Nop

	lwc1 $f0 8($1)                             # fp_sm1
	addu $0 $0 $0              #Nop
	cvt.w.s $f2 $f0
	mfc1 $6 $f2
	addi $4 $0 -1
	bne $4 $6 fail
	addu $0 $0 $0                              # Nop


	.data
div.s_:	.asciiz "Testing DIV.S\n"
fp_s2:	.float 2.0
fp_s3:	.float 3.0
fp_s1p5:.float 1.5
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 div.s_
	lui $a0 0x1000
	ori $a0 $a0 0x106
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lw $4 4($1)                              # fp_s1
	lwc1 $f0 4($1)                           # fp_s1
	addu $0 $0 $0              #Nop
	div.s $f2 $f0 $f0
	mfc1 $6 $f2
	addu $0 $0 $0                            # Nop
	bne $4 $6 fail
	addu $0 $0 $0                            # Nop

	lui $2 0x1000
	ori $2 $2 0x118
	lw $4 8($2)                                    # fp_s1p5
	lwc1 $f0 4($2)                                 # fp_s3
	lwc1 $f2 0($2)                                 # fp_s2
	addu $0 $0 $0              #Nop
	div.s $f4 $f0 $f2
	mfc1 $6 $f4
	addu $0 $0 $0                            # Nop
	bne $4 $6 fail
	addu $0 $0 $0                            # Nop


	.data
div.d_:	.asciiz "Testing DIV.D\n"
# EOS = 132...align to 138
fp_d2:	.double 2.0
fp_d3:	.double 3.0
fp_d1p5:.double 1.5
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 div.d_
	lui $a0 0x1000
	ori $a0 $a0 0x124
	syscall

	lui $1 0x1000
	ori $1 $1 0x90
	lw $4 0($1)                             # fp_d1
	lw $5 4($1)                             # fp_d1+4
	lwc1 $f0 0($1)                          # fp_d1
	lwc1 $f1 4($1)                          # fp_d1+4
	addu $0 $0 $0              #Nop
	div.d $f2 $f0 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	addu $0 $0 $0                            # Nop
	bne $4 $6 fail
	addu $0 $0 $0                            # Nop
	bne $5 $7 fail
	addu $0 $0 $0                            # Nop


	lui $2 0x1000
	ori $2 $2 0x138                          # Nop
	lw $4 16($2)                              # fp_d1p5
	lw $5 20($2)                              # fp_d1p5+4
	lwc1 $f0 8($2)                          # fp_d3
	lwc1 $f1 12($2)                          # fp_d3+4
	lwc1 $f2 0($2)                           # fp_d2
	lwc1 $f3 4($2)                          # fp_d2+4
	addu $0 $0 $0                            # Nop
	div.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	addu $0 $0 $0                            # Nop
	bne $5 $7 fail
	addu $0 $0 $0                            # Nop

	.data
mov.s_:	.asciiz "Testing MOV.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 mov.s_
	lui $a0 0x1000
	ori $a0 $a0 0x150
	syscall


	lui $1 0x1000
	ori $1 $1 0x68
	lw $4 4($1)                        # fp_s1
	lwc1 $f2 4($1)                     # fp_s1
	addu $0 $0 $0                      # Nop
	mov.s $f4 $f2
	mov.s $f6 $f4
	mfc1 $6 $f6
	addu $0 $0 $0                      # Nop
	bne $4 $6 fail
	addu $0 $0 $0                      # Nop

	.data
mov.d_:	.asciiz "Testing MOV.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 mov.d_
	lui $a0 0x1000
	ori $a0 $a0 0x15f
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lw $4 8($1)                     # fp_d1
	lw $5 12($1)                    # fp_d1+4
	lwc1 $f2 8($1)                  # fp_d1
	lwc1 $f3 12($1)                 # fp_d1+4
	addu $0 $0 $0                      # Nop
	mov.d $f4 $f2
	mov.d $f6 $f4
	mfc1 $6 $f6
	mfc1 $7 $f7
	bne $4 $6 fail
	addu $0 $0 $0                      # Nop
	bne $5 $7 fail
	addu $0 $0 $0                      # Nop


	.data
mul.s_:	.asciiz "Testing MUL.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 mul.s_
	lui $a0 0x1000
	ori $a0 $a0 0x16e

	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lw $4 4($1)                        # fp_s1
	lwc1 $f0 4($1)                     # fp_s1
	addu $0 $0 $0              #Nop
	mul.s $f2 $f0 $f0
	mfc1 $6 $f2
	addu $0 $0 $0                      # Nop
	bne $4 $6 fail
	addu $0 $0 $0                      # Nop

	lui $2 0x1000
	ori $2 $2 0x118
	lw $4 4($2)                        # fp_s3
	lwc1 $f0 8($2)                     # fp_s1p5
	lwc1 $f2 0($2)                     # fp_s2
	addu $0 $0 $0              #Nop
	mul.s $f4 $f0 $f2
	mfc1 $6 $f4
	addu $0 $0 $0                      # Nop
	bne $4 $6 fail
	addu $0 $0 $0                      # Nop

	.data
mul.d_:	.asciiz "Testing MUL.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 mul.d_
	lui $a0 0x1000
	ori $a0 $a0 0x17d
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lw $4 0($1)                              # fp_d1
	lw $5 4($1)                              # fp_d1+4
	lwc1 $f0 0($1)                           # fp_d1
	lwc1 $f1 4($1)                           # fp_d1+4
	addu $0 $0 $0              #Nop
	mul.d $f2 $f0 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	addu $0 $0 $0                      # Nop
	bne $5 $7 fail
	addu $0 $0 $0                      # Nop

	lui $2 0x1000
	ori $2 $2 0x138                          # Nop
	lw $4 8($2)                              # fp_d3
	lw $5 12($2)                             # fp_d3+4
	lwc1 $f0 16($2)                          # fp_d1p5
	lwc1 $f1 20($2)                          # fp_d1p5+4
	lwc1 $f2 0($2)                           # fp_d2
	lwc1 $f3 4($2)                           # fp_d2+4
	addu $0 $0 $0              #Nop
	mul.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	addu $0 $0 $0                      # Nop
	bne $5 $7 fail
	addu $0 $0 $0                      # Nop


	.data
neg.s_:	.asciiz "Testing NEG.S\n"
# 0x19b..0x19c
fp_sm3:	.float -3.0
	.text
	addi  $v0 $0 4	# syscall 4 (print_str)
#	la $a0 neg.s_
	lui $a0 0x1000
	ori $a0 $a0 0x18c
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lw $4 8($1)                             # fp_sm1
	lwc1 $f0 4($1)                          # fp_s1
	addu $0 $0 $0              #Nop
	neg.s $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0                           # Nop
	bne $4 $6 fail
	addu $0 $0 $0                           # Nop

	lui $2 0x1000
	ori $2 $2 0x118
	lw $4 4($2)                             # fp_s3
	lui $1 0x1000
	ori $1 $1 0x19c
	lwc1 $f0 0($1)                          # fp_sm3
	addu $0 $0 $0              #Nop
	neg.s $f2 $f0
	mfc1 $6 $f2
	addu $0 $0 $0                           # Nop
	bne $4 $6 fail
	addu $0 $0 $0                           # Nop

	.data
neg.d_:	.asciiz "Testing NEG.D\n"
fp_dm3:	.double -3.0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 neg.d_
	lui $a0 0x1000
	ori $a0 $a0 0x1a0
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lw $4 16($1)                           # fp_dm1
	lw $5 20($1)                           # fp_dm1+4
	lwc1 $f0 8($1)                         # fp_d1
	lwc1 $f1 12($1)                        # fp_d1+4
	addu $0 $0 $0              #Nop
	neg.d $f2 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	addu $0 $0 $0                          # Nop
	bne $5 $7 fail
	addu $0 $0 $0                          # Nop

	lui $2 0x1000
	ori $2 $2 0x138                        # Nop
	lw $4 8($2)                            # fp_d3
	lw $5 12($2)                           # fp_d3+4
	lui $1 0x1000
	ori $1 $1 0x1b0
	lwc1 $f0 0($1)                         # fp_dm3
	lwc1 $f1 4($1)                         # fp_dm3+4
	addu $0 $0 $0              #Nop
	neg.d $f4 $f0
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	addu $0 $0 $0                           # Nop
	bne $5 $7 fail
	addu $0 $0 $0                           # Nop


	.data
sub.s_:	.asciiz "Testing SUB.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sub.s_
	lui $a0 0x1000
	ori $a0 $a0 0x1b8
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lw $4 0($1)                            # fp_s0
	lwc1 $f0 0($1)                         # fp_s0
	addu $0 $0 $0              #Nop
	sub.s $f2 $f0 $f0
	mfc1 $6 $f2
	bne $4 $6 fail

	lw $4 8($1)                            # fp_sm1
	lw $5 4($1)                            # fp_s1
	lwc1 $f0 0($1)                         # fp_s0
	lwc1 $f2 4($1)                         # fp_s1
	addu $0 $0 $0              #Nop
	sub.s $f4 $f0 $f2
	mfc1 $6 $f4
	addu $0 $0 $0                          # Nop
	bne $4 $6 fail
	sub.s $f4 $f2 $f0
	mfc1 $6 $f4
	addu $0 $0 $0                          # Nop
	bne $5 $6 fail
	addu $0 $0 $0                          # Nop

	lui $2 0x1000
	ori $2 $2 0x118
	lw $4 8($2)                            # fp_s1p5
	lwc1 $f0 8($2)                         # fp_s1p5
	lwc1 $f2 4($2)                         # fp_s3
	addu $0 $0 $0              #Nop
	sub.s $f4 $f2 $f0
	mfc1 $6 $f4
	addu $0 $0 $0                          # Nop
	bne $4 $6 fail
	addu $0 $0 $0                          # Nop

	.data
sub.d_:	.asciiz "Testing SUB.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 sub.d_
	lui $a0 0x1000
	ori $a0 $a0 0x1c7
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lw $4 0($1)                            # fp_d0
	lw $5 4($1)                            # fp_d0+4
	lwc1 $f0 0($1)                         # fp_d0
	lwc1 $f1 4($1)                         # fp_d0+4
	addu $0 $0 $0              #Nop
	sub.d $f2 $f0 $f0
	mfc1 $6 $f2
	mfc1 $7 $f3
	bne $4 $6 fail
	addu $0 $0 $0                          # Nop
	bne $5 $7 fail
	addu $0 $0 $0                          # Nop

	lw $4 16($1)                           # fp_dm1
	lw $5 20($1)                           # fp_dm1+4
	lwc1 $f0 0($1)                         # fp_d0
	lwc1 $f1 4($1)                         # fp_d0+4
	lwc1 $f2 8($1)                         # fp_d1
	lwc1 $f3 12($1)                        # fp_d1+4
	addu $0 $0 $0              #Nop
	sub.d $f4 $f0 $f2
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	addu $0 $0 $0                          # Nop
	bne $5 $7 fail
	addu $0 $0 $0                          # Nop
	lw $4 8($1)                            # fp_d1
	lw $5 12($1)                           # fp_d1+4
	sub.d $f4 $f2 $f0
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	addu $0 $0 $0                          # Nop
	bne $5 $7 fail
	addu $0 $0 $0                          # Nop

	lui $2 0x1000
	ori $2 $2 0x138                        # Nop
	lw $4 16($2)                           # fp_d1p5
	lw $5 20($2)                           # fp_d1p5+4
	lwc1 $f0 16($2)                        # fp_d1p5
	lwc1 $f1 20($2)                        # fp_d1p5+4
	lwc1 $f2 8($2)                         # fp_d3
	lwc1 $f3 12($2)                        # fp_d3+4
	addu $0 $0 $0              #Nop
	sub.d $f4 $f2 $f0
	mfc1 $6 $f4
	mfc1 $7 $f5
	bne $4 $6 fail
	addu $0 $0 $0                          # Nop
	bne $5 $7 fail
	addu $0 $0 $0                          # Nop


	.data
c.eq.d_:	.asciiz "Testing C.EQ.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.eq.d_
	lui $a0 0x1000
	ori $a0 $a0 0x1d6
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lwc1 $f0 8($1)                        # fp_d1
	lwc1 $f1 12($1)                       # fp_d1+4
	lwc1 $f2 8($1)                        # fp_d1
	lwc1 $f3 12($1)                       # fp_d1+4
	lui $2 0x1000
	ori $2 $2 0x138
	lwc1 $f4 16($2)                       # fp_d1p5
	lwc1 $f5 20($2)                       # fp_d1p5+4
	addu $0 $0 $0                         # Nop
	c.eq.d $f0 $f2
	addu $0 $0 $0
        addu $0 $0 $0
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
        bc1t l200
	addu $0 $0 $0                         # Nop Delay slot
	j fail
 	addu $0 $0 $0                         # Nop Delay slot
l200:	c.eq.d $f0 $f4
	addu $0 $2 $2
        addu $0 $3 $3
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l201
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $4 $4                         # Nop Delay slot
l201:   addu $0 $5 $5


	.data
c.eq.s_:	.asciiz "Testing C.EQ.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.eq.s_
	lui $a0 0x1000
	ori $a0 $a0 0x1e6
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lwc1 $f0 4($1)                        # fp_s1
	lwc1 $f2 4($1)                        # fp_s1
	lui $2 0x1000
	ori $2 $2 0x118
	lwc1 $f4 8($2)                        # fp_s1p5
	addu $0 $0 $0                         # Nop Delay slot
	c.eq.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l210
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l210:	c.eq.s $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l211
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l211:   addu $0 $0 $0                         # Nop Delay slot



	.data
c.f.d_:	.asciiz "Testing C.F.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.f.d_
	lui $a0 0x1000
	ori $a0 $a0 0x1f6
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138
	lwc1 $f0 8($1)                             # fp_d1
	lwc1 $f1 12($1)                            # fp_d1+4
	lwc1 $f2 8($1)                             # fp_d1
	lwc1 $f3 12($1)                            # fp_d1+4
	lwc1 $f4 16($2)                            # fp_d1p5
	lwc1 $f5 20($2)                            # fp_d1p5+4
	c.f.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l220
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l220:	c.f.d $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l221
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l221:  	addu $0 $0 $0                         # Nop Delay slot

	.data
c.f.s_:	.asciiz "Testing C.F.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.f.s_
	lui $a0 0x1000
	ori $a0 $a0 0x205
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118
	lwc1 $f0 4($1)                          # fp_s1
	lwc1 $f2 4($1)                          # fp_s1
	lwc1 $f4 8($2)                          # fp_s1p5
	c.f.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l230
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l230:	c.f.s $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l231
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l231:  	addu $0 $0 $0                         # Nop Delay slot


	.data
c.le.d_:	.asciiz "Testing C.LE.D\n"
fp_dm2:	.double -2.0

	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.le.d_
	lui $a0 0x1000
	ori $a0 $a0 0x214
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # fp_d1+4
	lwc1 $f2 16($2)                       # fp_d1p5
	lwc1 $f3 20($2)                      # fp_d1p5+4
	lui $3 0x1000
	ori $3 $3 0x228
	lwc1 $f4 0($3)                      # fp_dm2
	lwc1 $f5 4($3)                      # fp_dm2+4
	c.le.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l240
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l240:	c.le.d $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l241
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l241:	c.le.d $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l242
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l242:	c.le.d $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l243
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l243:  	addu $0 $0 $0                         # Nop Delay slot



	.data
c.le.s_:	.asciiz "Testing C.LE.S\n"
fp_sm2:	.float -2.0
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.le.s_
	lui $a0 0x1000
	ori $a0 $a0 0x230
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 8($2)                       # fp_s1p5
	lui $3 0x1000
	ori $3 $3 0x240
	lwc1 $f4 0($3)                       # fp_sm2
	c.le.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l250
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l250:	c.le.s $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l251
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l251:	c.le.s $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l252
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l252:	c.le.s $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l253
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l253:  	addu $0 $0 $0                         # Nop Delay slot





	.data
c.lt.d_:	.asciiz "Testing C.LT.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.lt.d_
	lui $a0 0x1000
	ori $a0 $a0 0x244
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # fp_d1+4
	lwc1 $f2 16($2)                       # fp_d1p5
	lwc1 $f3 20($2)                      # fp_d1p5+4
	lui $3 0x1000
	ori $3 $3 0x220
	lwc1 $f4 0($3)                           # fp_dm2
	lwc1 $f5 4($3)                            # fp_dm2+4
	c.lt.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l260
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l260:	c.lt.d $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l261
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l261:	c.lt.d $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l262
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l262:	c.lt.d $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l263
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l263:


	.data
c.lt.s_:	.asciiz "Testing C.LT.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.lt.s_
	lui $a0 0x1000
	ori $a0 $a0 0x254
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 8($2)                       # fp_s1p5
	lui $3 0x1000
	ori $3 $3 0x240
	lwc1 $f4 0($3)                        # fp_sm2
	c.lt.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l270
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l270:	c.lt.s $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l271
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l271:	c.lt.s $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l272
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l272:	c.lt.s $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l273
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l273:


	.data
c.nge.d_:	.asciiz "Testing C.NGE.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.nge.d_
	lui $a0 0x1000
	ori $a0 $a0 0x264
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # fp_d1+4
	lwc1 $f2 16($2)                       # fp_d1p5
	lwc1 $f3 20($2)                      # fp_d1p5+4
	lui $3 0x1000
	ori $3 $3 0x220
	lwc1 $f4 0($3)                           # fp_dm2
	lwc1 $f5 4($3)                            # fp_dm2+4
	c.nge.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l280
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l280:	c.nge.d $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l281
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l281:	c.nge.d $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l282
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l282:	c.nge.d $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l283
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l283:


	.data
c.nge.s_:	.asciiz "Testing C.NGE.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.nge.s_
	lui $a0 0x1000
	ori $a0 $a0 0x275
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 8($2)                       # fp_s1p5
	lui $3 0x1000
	ori $3 $3 0x240
	lwc1 $f4 0($3)                        # fp_sm2
	c.nge.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l290
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l290:	c.nge.s $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l291
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l291:	c.nge.s $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l292
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l292:	c.nge.s $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l293
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l293:


	.data
c.ngle.d_:	.asciiz "Testing C.NGLE.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ngle.d_
	lui $a0 0x1000
	ori $a0 $a0 0x286
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # fp_d1+4
	lwc1 $f2 8($1)                      # fp_d1
	lwc1 $f3 12($1)                       # fp_d1+4
	lwc1 $f4 16($2)                       # fp_d1p5
	lwc1 $f5 20($2)                      # fp_d1p5+4
	c.ngle.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
l300:	c.ngle.d $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
l301:


	.data
c.ngle.s_:	.asciiz "Testing C.NGLE.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ngle.s_
	lui $a0 0x1000
	ori $a0 $a0 0x298
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 4($1)                       # fp_s1
	lwc1 $f4 8($2)                       # fp_s1p5
	c.ngle.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
l310:	c.ngle.s $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
l311:


	.data
c.ngl.d_:	.asciiz "Testing C.NGL.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ngl.d_
	lui $a0 0x1000
	ori $a0 $a0 0x2aa
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # Nop
	lwc1 $f2 8($1)                      # fp_d1
	lwc1 $f3 12($1)                       # Nop
	lwc1 $f4 16($2)                       # fp_d1p5
	lwc1 $f5 20($2)                      # fp_d1p5+4
	c.ngl.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l320
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l320:	c.ngl.d $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l321
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l321:


	.data
c.ngl.s_:	.asciiz "Testing C.NGL.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ngl.s_
	lui $a0 0x1000
	ori $a0 $a0 0x2bb
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 4($1)                       # fp_s1
	lwc1 $f4 8($2)                       # fp_s1p5
	c.ngl.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot	bc1f fail
	bc1t l330
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l330:	c.ngl.s $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l331
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l331:


	.data
c.ngt.d_:	.asciiz "Testing C.NGT.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ngt.d_
	lui $a0 0x1000
	ori $a0 $a0 0x2cc
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # Nop
	lwc1 $f2 16($2)                       # fp_d1p5
	lwc1 $f3 20($2)                      # fp_d1p5+4
	lui $3 0x1000
	ori $3 $3 0x220
	lwc1 $f4 0($3)                           # fp_dm2
	lwc1 $f5 4($3)                            # Nop
	c.ngt.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l340
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l340:	c.ngt.d $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l341
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l341:	c.ngt.d $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l342
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l342:	c.ngt.d $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l343
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l343:


	.data
c.ngt.s_:	.asciiz "Testing C.NGT.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ngt.s_
	lui $a0 0x1000
	ori $a0 $a0 0x2dd
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 8($2)                       # fp_s1p5
	lui $3 0x1000
	ori $3 $3 0x240
	lwc1 $f4 0($3)                        # fp_sm2
	c.ngt.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l350
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l350:	c.ngt.s $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l351
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l351:	c.ngt.s $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l352
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l352:	c.ngt.s $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l353
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l353:


	.data
c.ole.d_:	.asciiz "Testing C.OLE.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ole.d_
	lui $a0 0x1000
	ori $a0 $a0 0x2ee
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # Nop
	lwc1 $f2 16($2)                       # fp_d1p5
	lwc1 $f3 20($2)                      # fp_d1p5+4
	lui $3 0x1000
	ori $3 $3 0x220
	lwc1 $f4 0($3)                           # fp_dm2
	lwc1 $f5 4($3)                            # Nop
	c.ole.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l360
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l360:	c.ole.d $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l361
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l361:	c.ole.d $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l362
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l362:	c.ole.d $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l363
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l363:


	.data
c.ole.s_:	.asciiz "Testing C.OLE.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ole.s_
	lui $a0 0x1000
	ori $a0 $a0 0x2ff
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 8($2)                       # fp_s1p5
	lui $3 0x1000
	ori $3 $3 0x240
	lwc1 $f4 0($3)                        # fp_sm2
	c.ole.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l370
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l370:	c.ole.s $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l371
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l371:	c.ole.s $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l372
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l372:	c.ole.s $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l373
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l373:


	.data
c.seq.d_:	.asciiz "Testing C.SEQ.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.seq.d_
	lui $a0 0x1000
	ori $a0 $a0 0x310
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # Nop
	lwc1 $f2 8($1)                      # fp_d1
	lwc1 $f3 12($1)                       # Nop
	lwc1 $f4 16($2)                       # fp_d1p5
	lwc1 $f5 20($2)                      # fp_d1p5+4
	c.seq.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l380
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l380:	c.seq.d $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l381
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l381:


	.data
c.seq.s_:	.asciiz "Testing C.SEQ.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.seq.s_
	lui $a0 0x1000
	ori $a0 $a0 0x321
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 4($1)                       # fp_s1
	lwc1 $f4 8($2)                       # fp_s1p5
	c.seq.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l390
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l390:	c.seq.s $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l391
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l391:


	.data
c.sf.d_:	.asciiz "Testing C.SF.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.sf.d_
	lui $a0 0x1000
	ori $a0 $a0 0x332
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # Nop
	lwc1 $f2 8($1)                      # fp_d1
	lwc1 $f3 12($1)                       # Nop
	lwc1 $f4 16($2)                       # fp_d1p5
	lwc1 $f5 20($2)                      # fp_d1p5+4
	c.sf.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
l400:	c.sf.d $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
l401:


	.data
c.sf.s_:	.asciiz "Testing C.SF.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.sf.s_
	lui $a0 0x1000
	ori $a0 $a0 0x342
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 4($1)                       # fp_s1
	lwc1 $f4 8($2)                       # fp_s1p5
	c.sf.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
l410:	c.sf.s $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
l411:


	.data
c.ueq.d_:	.asciiz "Testing C.UEQ.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ueq.d_
	lui $a0 0x1000
	ori $a0 $a0 0x352
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # Nop
	lwc1 $f2 8($1)                      # fp_d1
	lwc1 $f3 12($1)                       # Nop
	lwc1 $f4 16($2)                       # fp_d1p5
	lwc1 $f5 20($2)                      # fp_d1p5+4
	c.ueq.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l420
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l420:	c.ueq.d $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l421
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l421:


	.data
c.ueq.s_:	.asciiz "Testing C.UEQ.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ueq.s_
	lui $a0 0x1000
	ori $a0 $a0 0x363
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 4($1)                       # fp_s1
	lwc1 $f4 8($2)                       # fp_s1p5
	c.ueq.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l430
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l430:	c.ueq.s $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l431
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l431:


	.data
c.ule.d_:	.asciiz "Testing C.ULE.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ule.d_
	lui $a0 0x1000
	ori $a0 $a0 0x374
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # Nop
	lwc1 $f2 16($2)                       # fp_d1p5
	lwc1 $f3 20($2)                      # fp_d1p5+4
	lui $3 0x1000
	ori $3 $3 0x220
	lwc1 $f4 0($3)                           # fp_dm2
	lwc1 $f5 4($3)                            # Nop
	c.ule.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l440
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l440:	c.ule.d $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l441
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l441:	c.ule.d $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l442
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l442:	c.ule.d $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l443
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l443:


	.data
c.ule.s_:	.asciiz "Testing C.ULE.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.ule.s_
	lui $a0 0x1000
	ori $a0 $a0 0x385
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 8($2)                       # fp_s1p5
	lui $3 0x1000
	ori $3 $3 0x240
	lwc1 $f4 0($3)                        # fp_sm2
	c.ule.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l450
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l450:	c.ule.s $f2 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l451
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l451:	c.ule.s $f0 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l452
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l452:	c.ule.s $f4 $f0
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1f fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1t l453
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l453:


	.data
c.un.d_:	.asciiz "Testing C.UN.D\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.un.d_
	lui $a0 0x1000
	ori $a0 $a0 0x396
	syscall

	lui $1 0x1000
	ori $1 $1 0x88
	lui $2 0x1000
	ori $2 $2 0x138

	lwc1 $f0 8($1)                      # fp_d1
	lwc1 $f1 12($1)                       # Nop
	lwc1 $f2 8($1)                      # fp_d1
	lwc1 $f3 12($1)                       # Nop
	lwc1 $f4 16($2)                       # fp_d1p5
	lwc1 $f5 20($2)                      # fp_d1p5+4
	c.un.d $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l460
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l460:	c.un.d $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l461
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l461:


	.data
c.un.s_:	.asciiz "Testing C.UN.S\n"
	.text
	addi $v0 $0 4	# syscall 4 (print_str)
#	la $a0 c.un.s_
	lui $a0 0x1000
	ori $a0 $a0 0x3a6
	syscall

	lui $1 0x1000
	ori $1 $1 0x68
	lui $2 0x1000
	ori $2 $2 0x118

	lwc1 $f0 4($1)                       # fp_s1
	lwc1 $f2 4($1)                       # fp_s1
	lwc1 $f4 8($2)                       # fp_s1p5
	c.un.s $f0 $f2
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l470
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l470:	c.un.s $f0 $f4
	addu $0 $0 $0                         # Nop Delay slot
	addu $0 $0 $0                         # Nop Delay slot
	bc1t fail
	addu $0 $0 $0                         # Nop Delay slot
	bc1f l471
	addu $0 $0 $0                         # Nop Delay slot
	j fail
	addu $0 $0 $0                         # Nop Delay slot
l471:



# Done !!!
	.text
	addi $2 $0 4	# syscall 4 (print_str)
#	la $a0 pt
	lui $a0, 0x1000
	ori $a0 $a0 0xd
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

