.section .text.boot
.code16

.global _start
_start:
    cli

    /* Initialize stack */
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    movw $0x7c00, %sp

    cld
    sti

    /* Store disk number */
    movb %dl, drive_num

    /* Enable A20 line */
    in $0x92, %al
    test $2, %al
    jnz a20_enabled
    or $2, %al
    and $0xfe, %al
    out %al, $0x92

a20_enabled:
    /* Retrieve disk number and set DAP */
    mov drive_num, %dl
    mov $disk_address_packet, %si

    /* Perform read */
    call read
    jc read_err

    /* Switch to Protected mode */
    cli
    lgdt gdtr

    movl %cr0, %eax
    orl $1, %eax
    movl %eax, %cr0

    ljmp $0x08, $pmode

.code32

pmode:
    /* Set data segments */
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss

    /* Transfer control to (what should be) the decompressor */
    jmp 0x40000

.code16

read_err:
    mov $read_err_msg, %si
    call print
end:
    hlt
    jmp end

#include "print.S"
#include "read.S"
#include "gdt.S"

read_err_msg:
    .asciz "! Read\n\r"

drive_num:
    .byte 0x00

disk_address_packet:
    .byte 0x10
    .byte 0x00
num_sectors:
    .word 15
offset:
    .word 0x0000
segment:
    .word 0x4000
sector:
    .long 0x00000001

.space 510 - (. - _start)
.word 0xaa55
