        .text
        .globl main
main:   li.s $f0, 0.11111
        li.s $f1, 0.12345
        li.d $f0, 0.22222
        jr $ra          # retrun to caller