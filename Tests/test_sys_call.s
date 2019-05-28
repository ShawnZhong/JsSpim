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

    nop         # please input 17
	li $v0 5	# syscall 5 (read_int)
	syscall     # please input 17
	bne $v0 17 fail

    nop         # please input 1717
	li $v0 5	# syscall 5 (read_int)
	syscall     # please input 1717
	bne $v0 1717 fail

    nop         # please input 17.18
	li $v0 6	# syscall 6 (read_float)
	syscall     # please input 17.18
	lwc1 $f2 fp_c1
	c.eq.s $f0, $f2
	bc1f fail

    nop         # please input 1700.18
	li $v0 6	# syscall 6 (read_float)
	syscall     # please input 1700.18
	lwc1 $f2 fp_c2
	c.eq.s $f0, $f2
	bc1f fail

    nop         # please input 17.18e10
	li $v0 7	# syscall 7 (read_double)
	syscall     # please input 17.18e10
	lwc1 $f2 fp_c3
	lwc1 $f3 fp_c3+4
	c.eq.d $f0, $f2
	bc1f fail

    nop         # please input 1700.18e10
	li $v0 7	# syscall 7 (read_double)
	syscall     # please input 1700.18e10
	lwc1 $f2 fp_c4
	lwc1 $f3 fp_c4+4
	c.eq.d $f0, $f2
	bc1f fail


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
