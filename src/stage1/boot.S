.section .text.boot
.code16

#define INFO(x) mov $info_prefix, %si; call print; mov $x, %si; call print; mov $line_break, %si; call print
#define WARN(x) mov $warn_prefix, %si; call print; mov $x, %si; call print; mov $line_break, %si; call print
#define ERR(x) mov $error_prefix, %si; call print; mov $x, %si; call print; mov $line_break, %si; jmp err

.global _start
_start:
    jmp skip_bpb
    nop

skip_bpb:
    cli

    /* initialize stack */
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov $0x7c00, %sp

    cld
    sti

    INFO(stack_msg)

    jmp end

err:
    call print

end:
    hlt
    jmp end

1:
    mov $0x0e, %ah
    int $0x10
print:
    lodsb
    cmp $0, %al
    jne 1b
    ret

/* ---------- VARIABLES ---------- */

drive_num:
    .byte 0x00

disk_address_packet:
    .byte 0x10
    .byte 0x00
num_sectors:
    .word 0x0040
offset:
    .word 0x0000
segment:
    .word 0x1000
sector:
    .quad 0x00000000

info_prefix:
    .asciz "[INFO]  Maize: "
warn_prefix:
    .asciz "[WARN]  Maize: "
error_prefix:
    .asciz "[ERROR] Maize: "
line_break:
    .asciz "\n\r"

stack_msg:
    .asciz "Stack initialized"

.space 510 - (. - _start)
.word 0xaa55
