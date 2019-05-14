.text
fib:
	sw    $ra, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	sw    $fp, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	subu  $sp, $sp, 0
	addu  $fp, $sp, 8

	lw    $v0, 4($fp)
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	li    $v0, 0
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	lw    $v1, 4($sp)	#POP
	addu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	seq   $v0, $v0, $v1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	li    $v1, 1
	beq   $v0, $v1, .L2
	lw    $v0, 4($fp)
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	li    $v0, 1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	lw    $v1, 4($sp)	#POP
	addu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	seq   $v0, $v0, $v1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	j     .L1
.L2: 
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
.L1: 
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	li    $v1, 0
	beq   $v0, $v1, .L0
	li    $v0, 1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	j     _fib_exit

.L0: 
	lw    $v0, 4($fp)
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	li    $v0, 1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	lw    $v1, 4($sp)	#POP
	addu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	sub   $v0, $v0, $v1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	jal   fib
	lw    $v0, 4($fp)
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	li    $v0, 2
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	lw    $v1, 4($sp)	#POP
	addu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	sub   $v0, $v0, $v1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	jal   fib
	lw    $v1, 4($sp)	#POP
	addu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	add   $v0, $v0, $v1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	j     _fib_exit

_fib_exit:
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	lw    $ra, 0($fp)
	move  $t0, $fp
	lw    $fp, -4($fp)
	move  $sp, $t0
	addi  $sp, $sp, 4
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	jr    $ra

.text
main:
__start:
	sw    $ra, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	sw    $fp, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	subu  $sp, $sp, 4
	addu  $fp, $sp, 12

	li    $v0, 0
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	sw    $v0, -8($fp)

.L4: 
	lw    $v0, -8($fp)
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	li    $v0, 20
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	lw    $v1, 4($sp)	#POP
	addu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	slt   $v0, $v0, $v1
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4
	lw    $v0, 4($sp)	#POP
	addu  $sp, $sp, 4
	li    $v1, 0
	beq   $v0, $v1, .L3
	lw    $v0, -8($fp)
	sw    $v0, 0($sp)	#PUSH
	subu  $sp, $sp, 4

	jal   fib
	lw    $a0, 4($sp)	#POP
	addu  $sp, $sp, 4
	li    $v0, 1
	syscall

.data
.L5: .asciiz "\n"
.text
	la    $a0, .L5
	li    $v0, 4
	syscall

	lw    $v0, -8($fp)
	addi  $v0, $v0, 1
	sw    $v0, -8($fp)

	j     .L4
.L3: 
_main_exit:
	li    $v0, 10
	syscall
