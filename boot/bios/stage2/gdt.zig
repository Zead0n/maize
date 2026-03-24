comptime {
    asm (
        \\gdtr:
        \\.word (gdt_end - gdt) - 1
        \\.long gdt
        \\
        \\gdt:
        \\
        \\.quad 0
        \\
        \\.word 0xffff
        \\.word 0
        \\.byte 0
        \\.byte 0x9a
        \\.byte 0xcf
        \\.byte 0
        \\
        \\.word 0xffff
        \\.word 0
        \\.byte 0
        \\.byte 0x92
        \\.byte 0xcf
        \\.byte 0
        \\
        \\.word 0xffff
        \\.word 0
        \\.byte 0
        \\.byte 0x9a
        \\.byte 0x0f
        \\.byte 0
        \\
        \\.word 0xffff
        \\.word 0
        \\.byte 0
        \\.byte 0x92
        \\.byte 0x0f
        \\.byte 0
        \\
        \\gdt_end:
    );
}

pub const Gdt = enum(u32) {
    Null,
    Code32,
    Data32,
    Code16,
    Data16,
};

pub fn descriptorSegment(gdt: Gdt) u32 {
    return @as(u32, @intFromEnum(gdt) * 0x8);
}
