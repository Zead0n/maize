const MAX_E820_ENTRIES = 256;
const MAGIC_SMAP = 0x534D4150;

const SmapError = error{
    Unsupported,
    FailedMemoryMap,
    TooManyEntries,
};

const MemoryType = enum(u32) {
    Null = 0,
    Free = 1,
    Reserved = 2,
    Reclaimable = 3,
    NonVolatile = 4,
    Bad = 5,
};

const SmapEntry = packed struct {
    base: u64,
    length: u64,
    type: MemoryType,
    acpi: u32,
};

pub fn detect_memory() SmapError![]SmapEntry {
    var entries: [MAX_E820_ENTRIES]SmapEntry = undefined;
    var entries_count: usize = 0;

    var count_id: u32 = 0;

    for (0..MAX_E820_ENTRIES) |i| {
        var entry: SmapEntry = undefined;

        var signature: u32 = undefined;
        var entry_size: u32 = undefined;

        asm volatile ("int $0x15"
            : [signature] "={eax}" (signature),
              [ret_id] "={ebx}" (count_id),
              [ret_size] "={ecx}" (entry_size),
            : [func] "{eax}" (0xe820),
              [id] "{ebx}" (count_id),
              [size] "{ecx}" (24),
              [magic] "{edx}" (MAGIC_SMAP),
              [buffer] "{edi}" (&entry),
        );

        if (@as(u8, @truncate(signature >> 8)) == 0x86)
            return error.Unsupported;

        if (signature != MAGIC_SMAP)
            return error.FailedMemoryMap;

        if (entry_size < 20 and (entry.acpi & 1) == 0)
            continue;

        entries[i] = entry;
        entries_count += 1;

        if (count_id == 0)
            return entries[0..entries_count];
    }

    return error.TooManyEntries;
}
