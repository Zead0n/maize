pub const GlobalDescriptorEntry = packed struct {
    limit_0_15: u16,
    base_0_23: u24,
    access: u8,
    limit_16_19: u4,
    flags: u4,
    base_24_31: u8,
};

const Gdtr = packed struct {
    size: u16,
    ptr: *anyopaque,
};

pub const NULL_DESCRIPTOR = GlobalDescriptorEntry{
    .limit_0_15 = 0,
    .limit_16_19 = 0,
    .base_0_23 = 0,
    .base_24_31 = 0,
    .access = 0,
    .flags = 0,
};
pub const KERNEL_CODE_SEGMENT_32 = GlobalDescriptorEntry{
    .limit_0_15 = 0xffff,
    .limit_16_19 = 0xf,
    .base_0_23 = 0,
    .base_24_31 = 0,
    .access = 0b10011011,
    .flags = 0b1100,
};
pub const KERNEL_DATA_SEGMENT_32 = GlobalDescriptorEntry{
    .limit_0_15 = 0xffff,
    .limit_16_19 = 0xf,
    .base_0_23 = 0,
    .base_24_31 = 0,
    .access = 0b10010011,
    .flags = 0b1100,
};

pub fn enable_unreal() void {
    var ds: u32 = 0;
    var ss: u32 = 0;
    asm volatile (
        \\mov %%ds, %[ds]
        \\mov %%ss, %[ss]
        : [ds] "=r" (ds),
          [ss] "=r" (ss),
    );
    defer asm volatile (
        \\ mov %[ds], %%ds
        \\ mov %[ss], %%ss
        :
        : [ds] "r" (ds),
          [ss] "r" (ss),
    );

    write_cr0(read_cr0() | 1);

    asm volatile (
        \\mov %%bx, %%ds
        \\mov %%bx, %%ss
        \\sti
        :
        : [seg] "{bx}" (0x10),
    );

    write_cr0(read_cr0() & 0xfffe);
}

fn enable_pmode() void {
    write_cr0(read_cr0() | 1);
}

pub fn load_gdt(descriptors: []GlobalDescriptorEntry) void {
    const gdtr = Gdtr{
        .size = @truncate((@sizeOf(u64) * descriptors.len) - 1),
        .ptr = descriptors.ptr,
    };

    asm volatile (
        \\lgdt %[gdtp:a]
        :
        : [gdtp] "X" (&gdtr),
    );
}

fn read_cr0() u32 {
    return asm volatile ("mov %%cr0, %[ret]"
        : [ret] "=r" (-> u32),
    );
}

fn write_cr0(value: u32) void {
    return asm volatile ("mov %[val], %%cr0"
        :
        : [val] "r" (value),
    );
}
