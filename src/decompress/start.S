.extern bss_begin
.extern bss_end

.section .text.start
.global _start
_start:
    cld

    xor %al, %al
    mov bss_begin, %edi
    mov bss_end, %ecx
    sub bss_begin, %ecx
    rep stosb

    jmp decompress
