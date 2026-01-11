.section .text.boot
.code16

.global _start
_start:
    cli

    /* initialize stack */
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
    mov drive_num, %dl
    mov $disk_address_packet, %si
    call read
    jc read_err

    cli
    lgdt gdtr

    movl %cr0, %eax
    orl $1, %eax
    movl %eax, %cr0

    ljmp $0x08, $pmode

.code32

pmode:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss

    jmp 0x40000

.code16

#include "gdt.S"

read_err:
    mov $read_err_msg, %si
    call print
end:
    hlt
    jmp end

/* ---------- UTILITY ---------- */

/*
 * 'call print'
 *
 * INPUT:
 * %si = Null terminated string
 */
1:
    mov $0x0e, %ah
    int $0x10
print:
    lodsb
    cmp $0, %al
    jne 1b
    ret

/*
 * 'call read'
 *
 * Read with DAP (AH = 0x42, INT = 0x13).
 * Errors if failed.
 *
 * NOTE: Maybe a CHS as a fallback in the future?
 *
 * INPUT:
 * %ds:%si = Data packet address
 * %dl = Drive number
 *
 * RETURN:
 * `Carry` set if error
 */
read:
    push %dx

    /* Check if hard drive */
    cmpb $0x80, %dl
    jb read.failed

    /* Check for LBA support */
    movw $0x55aa, %bx
    movb $0x41, %ah
    int $0x13

    jc read.failed
    cmpw $0xaa55, %bx
    jne read.failed
    testb $0x01, %cl
    jz read.failed

    pop %dx

    movb $0x42, %ah
    int $0x13
    jc read.failed
    jmp read.return
read.failed:
    stc
read.return:
    ret

/* ---------- VARIABLES ---------- */

drive_num:
    .byte 0x00

disk_address_packet:
    .byte 0x10
    .byte 0
num_sectors:
    .word 15
offset:
    .word 0
segment:
    .word 0x4000
sector:
    .long 1

read_err_msg:
    .asciz "Read err\n\r"

.space 510 - (. - _start)
.word 0xaa55
