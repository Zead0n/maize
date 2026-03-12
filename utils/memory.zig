pub const MemoryType = enum(u32) {
    Null = 0,
    Free = 1,
    Reserved = 2,
    Reclaimable = 3,
    NonVolatile = 4,
    Bad = 5,
};

pub const MemoryEntry = packed struct {
    base: u64,
    length: u64,
    type: MemoryType,
};
