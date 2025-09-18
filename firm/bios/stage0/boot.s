.code16

.global _start

_start:
	mov $0x7c00, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss

	mov %ax, %sp

	cld

	mov  $msg, %si
	call print

_end:
	hlt
	jmp _end

print:
	mov $0x00, %bx
	mov $0x0e, %ah

print_continue:
	lodsb
	cmp $0, %al
	je  print_done
	int $0x10
	jmp print

print_done:
	ret

msg:
	.asciz "Hello maize"

#
.space 510 - (. - _start)
.word  0xaa55

