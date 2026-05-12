.section .text.boot
.code16

.set STAGE2_DEST, 0xf000

.global _start
_start:
    jmp after_bpb
    nop

.org 0x03, 0x00
bpb_start:
bpb_end:
.org 0x5a, 0x00

.extern firstStage
.type firstStage, @function
after_bpb:
    /* Initialize stack */
    cli
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    movw $0x7c00, %sp
    sti

    cld

    mov %dl, drive

    /* Check for ext13 */
    mov $0x4100, %ax
    mov $0x55aa, %bx
    mov drive, %dl
    int $0x13

    cmpw $0xaa55, %bx
    jne ext_err

    /* Load stage2 */
    mov $0x4200, %ax
    mov drive, %dl
    mov $dap_addr, %si
    int $0x13

    cmpw $0, %ax
    jne read_err

    ljmp $0, $(STAGE2_DEST)


ext_err:
    mov $65, %al
    jmp _err
read_err:
    mov $82, %al
    jmp _err
_err:
    mov $0x0e, %ah
    int $0x10
    mov $33, %al
    int $0x10
spin:
    hlt
    jmp spin

drive:
    .byte 0

dap_addr:
    .byte 0x10
    .byte 0
    .word 63
    .word STAGE2_DEST
    .word 0
    .quad 1
