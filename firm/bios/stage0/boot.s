.section .boot, "awx"
.global  _start
.code16

_start:
	xor %ax, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss
	mov %ax, %fs
	mov %ax, %gs

	mov $0x7c00, %sp

a20:
	in   $92, %al
	test $2, %al
	jnz  after_a20
	or   $2, %al
	and  $0xfe, %al
	out  %al, $92

extention_check:

after_a20:

_end:
	hlt
	jmp _end

#
.space 510 - ( . - _start)
.word  0xaa55
