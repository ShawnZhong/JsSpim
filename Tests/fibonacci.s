.text
main:
la $a0, prompt
li $v0, 4           # print
syscall

li $v0, 5           # read int
syscall

move $t4, $v0       # $t4 <- n
addi $t4, $t4, 1

li $t2, 1           # $t2 is an index i

loop:
move $a0, $t2
move $v0, $t2
jal fib             # call fib (n)
move $t3, $v0       # result is in $t3

# Output message and n
la $a0, result      # Print F_
li $v0, 4
syscall

move $a0, $t2       # Print n
li $v0, 1
syscall

la $a0, result2     # Print =
li $v0, 4
syscall

move $a0, $t3       # Print the answer
li $v0, 1
syscall

la $a0, endl        # Print '\n'
li $v0, 4
syscall

addi $t2, $t2, 1    # i++
bne $t2, $t4, loop

# End program
li $v0, 10
syscall

fib:
# Compute and return fibonacci number
beqz $a0, zero      # if n == 0 return 0
beq $a0, 1, one     # if n == 1 return 1

# Calling fib(n-1)
sub $sp, $sp, 4     # storing return address
sw $ra, 0($sp)

sub $a0, $a0, 1     # n-1
jal fib             # fib(n-1)
add $a0, $a0, 1

lw $ra, 0($sp)      # restoring return address
add $sp, $sp, 4


sub $sp, $sp, 4     # Push return value
sw $v0, 0($sp)

# Calling fib(n-2)
sub $sp, $sp, 4     # storing return address
sw $ra, 0($sp)

sub $a0, $a0, 2     # n = n-2
jal fib             # call fib(n-2)
add $a0, $a0, 2

lw $ra, 0($sp)      # restoring return address
add $sp, $sp, 4
# ---------------
lw $s7, 0($sp)      # Pop return value
add $sp, $sp, 4

add $v0, $v0, $s7   # f(n - 2)+fib(n-1)

jr $ra              # decrement/next in stack

zero:
li $v0, 0
jr $ra

one:
li $v0, 1
jr $ra

.data
prompt: .asciiz "The code is based on Adel Zare's answer at <a href='https://stackoverflow.com/questions/22976456'>StackOverflow</a>\nThis program calculates Fibonacci sequence from 1 to n.\nPlease enter a non-negative number n:\n"
result: .asciiz "F_"
result2: .asciiz " = "
endl: .asciiz "\n"