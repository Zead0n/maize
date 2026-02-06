const gdt = @import("gdt.zig");
const cpu = @import("cpu.zig");

pub fn enableUnreal(descriptors: []gdt.GlobalDescriptorEntry) void {
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

    cpu.disable_int();
    gdt.load_gdt(descriptors);
    writeCR0(readCR0() | 1);

    asm volatile (
        \\mov %[seg], %%ds
        \\mov %[seg], %%ss
        \\sti
        :
        : [seg] "r" (0x10),
    );

    writeCR0(readCR0() & 0xfffe);
    cpu.enable_int();
}

fn readCR0() u32 {
    return asm volatile ("mov %%cr0, %[ret]"
        : [ret] "=r" (-> u32),
    );
}

fn writeCR0(value: u32) void {
    return asm volatile ("mov %[val], %%cr0"
        :
        : [val] "r" (value),
    );
}
