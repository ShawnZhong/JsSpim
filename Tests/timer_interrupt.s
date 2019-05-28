        .text
        .globl main
main:
    # allow hardware interrupts
    mfc0 $t0, $12   # get status register
    ori $t0, $t0, 0xff01
    mtc0 $t0, $12

    # set up a timer
    li $t0, 5       # get a timer interrupt every second     
    mtc0 $t0, $11   # set up compare register
    mtc0 $zero, $9

forever:    
    addi $s0, $s0, 1   # 1,2,3,4,... 
    j forever

    jr $ra

#--- END MAIN 


        .kdata
save0:   .word 0
save1:   .word 0

msg: .asciiz "\nGot a timer interrupt\n"

        .ktext 0x80000180
timer_handler:
	sw $a0 save0
	sw $v0 save1
		
	li $v0, 4              # print a message
	la $a0, msg
	syscall

    # reset timer
    li $t0, 100            # get a timer interrupt every second     
    mtc0 $t0, $11          # set up compare register
    mtc0 $zero, $9
	
	lw $a0 save0
	lw $v0 save1
	
    mtc0 $zero $13          # Clear Cause register
    mfc0 $k0 $12            # Set Status register
    ori  $k0 0x1            # Interrupts enabled
    mtc0 $k0 $12
    eret
