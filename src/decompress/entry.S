.extern bss_begin
.extern bss_end

.section .entry
.align 16
.global _start
_start:
    cld

    xor %al, %al
    mov bss_begin, %edi
    mov bss_end, %ecx
    sub bss_begin, %ecx
    rep stosb

    call decompress_entry
