pub const thunk: *Thunk = @ptrFromInt(0x8000 - 64);

comptime {
    asm (
        \\.code32
        \\_esp:
        \\  .long 0
        \\_cr0:
        \\  .long 0
        \\_gdt:
        \\  .quad 0
        \\_idt:
        \\  .quad 0
        \\_rm_idt:
        \\  .word 0x3ff
        \\  .long 0
        \\
        \\.global realInt
        \\realInt:
        \\    movb 4(%esp), %al
        \\    movb %al, _int
        \\
        \\    pushf
        \\    pusha
        \\
        \\    movl %esp, %eax
        \\    movl %eax, _esp
        \\
        \\    sgdt _gdt
        \\    sidt _idt
        \\
        \\    lidt _rm_idt
        \\
        \\    ljmp $0x18, $realInt.0
        \\.code16
        \\realInt.0:
        \\    movw $0x20, %ax
        \\    movw %ax, %ds
        \\    movw %ax, %es
        \\    movw %ax, %fs
        \\    movw %ax, %gs
        \\    movw %ax, %ss
        \\
        \\    movl %cr0, %eax
        \\    movl %eax, _cr0
        \\    and $0xfe, %al
        \\    movl %eax, %cr0
        \\
        \\    ljmp $0, $realInt.1
        \\realInt.1:
        \\    xor %ax, %ax
        \\    mov %ax, %ds
        \\    mov %ax, %es
        \\    mov %ax, %fs
        \\    mov %ax, %gs
        \\    mov %ax, %ss
        \\
        \\    movl $(0x8000 - 64), %esp
        \\
        \\    pop %eax
        \\    pop %ebx
        \\    pop %ecx
        \\    pop %edx
        \\    pop %ebp
        \\    pop %esi
        \\    pop %edi
        \\    pop %es
        \\
        \\    sti
        \\
        \\    .byte 0xcd
        \\_int:
        \\    .byte 0
        \\
        \\    cli
        \\
        \\    push %es
        \\    push %edi
        \\    push %esi
        \\    push %ebp
        \\    push %edx
        \\    push %ecx
        \\    push %ebx
        \\    push %eax
        \\
        \\    lgdt _gdt
        \\    lidt _idt
        \\
        \\    movl _cr0, %eax
        \\    movl %eax, %cr0
        \\
        \\    ljmp $0x8, $realInt.2
        \\.code32
        \\realInt.2:
        \\    movw $0x10, %ax
        \\    movw %ax, %ds
        \\    movw %ax, %es
        \\    movw %ax, %fs
        \\    movw %ax, %gs
        \\    movw %ax, %ss
        \\
        \\    movl _esp, %esp
        \\
        \\    popa
        \\    popf
        \\
        \\    ret
    );
}

extern fn realInt(int: u8) void;

pub const Thunk = packed struct {
    eax: u32 = 0,
    ebx: u32 = 0,
    ecx: u32 = 0,
    edx: u32 = 0,
    ebp: u32 = 0,
    esi: u32 = 0,
    edi: u32 = 0,
    es: u16 = 0,

    pub fn int(self: @This(), num: u8) @This() {
        self.write();
        realInt(num);
        return thunk.*;
    }

    fn write(self: @This()) void {
        thunk.* = self;
    }
};
