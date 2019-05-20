.data
   a:  .word  1

.text
main:
   la $a0, a
   li $a1, 2
   sw $a1 ($a0)

   la $a0, a
   li $a1, 3
   sw $a1 ($a0)

   la $a0, a
   li $a1, 4
   sw $a1 ($a0)

   la $a0, a
   li $a1, 5
   sw $a1 ($a0)

   jr $ra