pub const GlobalDescriptorEntry = packed struct {
    limit_0_15: u16,
    base_0_23: u24,
    access: u8,
    limit_16_19: u4,
    flags: u4,
    base_24_31: u8,
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

const Gdtr = packed struct {
    size: u16,
    ptr: u32,
};

pub fn load_gdt(descriptors: []GlobalDescriptorEntry) void {
    const gdtr = Gdtr{
        .size = @truncate((@sizeOf(u64) * descriptors.len) - 1),
        .ptr = @intFromPtr(descriptors.ptr),
    };

    asm volatile (
        \\lgdt %[gdtp:a]
        :
        : [gdtp] "X" (&gdtr),
    );
}
