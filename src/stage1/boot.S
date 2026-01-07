.section .text.boot
.code16

#define LOG_INFO(x) mov $info_prefix, %si; call print; mov $x, %si; call print; mov $line_break, %si; call print
#define LOG_WARN(x) mov $warn_prefix, %si; call print; mov $x, %si; call print; mov $line_break, %si; call print
#define LOG_ERR(x) mov $error_prefix, %si; call print; mov $x, %si; call print; mov $line_break, %si; jmp err

.global _start
_start:
    cli

    /* initialize stack */
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov $0x7c00, %sp

    cld
    sti

    LOG_INFO(stack_msg)

    /* Enable A20 line */
    in $0x92, %al
    test $2, %al
    jnz a20_enabled
    or $2, %al
    and $0xfe, %al
    out %al, $0x92
    jmp a20_enabled

a20_enabled:
    jmp end

/* ---------- ERRORS ---------- */

disk_err:
    LOG_ERR(disk_err_msg)
disk_err_msg:
    .asciz "Dubious disk value"

err:
    call print

/* ---------- LOOP / HALT ---------- */
end:
    hlt
    jmp end

/* ---------- UTILITY ---------- */

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

