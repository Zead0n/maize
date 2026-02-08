const std = @import("std");
const cpu = @import("cpu.zig");
const gdt = @import("gdt.zig");
const a20 = @import("a20.zig");
const console = @import("console.zig");
const memmap = @import("memmap.zig");
const mode = @import("mode.zig");

const GDT = [_]gdt.GlobalDescriptorEntry{
    gdt.NULL_DESCRIPTOR,
    gdt.KERNEL_CODE_SEGMENT_32,
    gdt.KERNEL_DATA_SEGMENT_32,
};

export fn _start() callconv(.naked) noreturn {
    asm volatile ("jmp %[stage2_entry:a]"
        :
        : [stage2_entry] "X" (&stageTwoEntry),
    );
}

fn stageTwoEntry() callconv(.c) noreturn {
    mode.enableUnreal(@constCast(&GDT));
    console.clear();
    a20.enable() catch @panic("Could not enable A20 line");

    const fpu_feature = (1 << 0);
    const pae_feature = (1 << 6);
    const pge_feature = (1 << 13);
    const fxsr_feature = (1 << 24);
    const required_cpu_features = fpu_feature | pae_feature | pge_feature | fxsr_feature;
    if (cpu.cpuidFeatures() & required_cpu_features != required_cpu_features)
        @panic("CPU missing required features");

    const memory_map = memmap.detectMemory() catch |err| switch (err) {
        error.Unsupported => @panic("E820 unsupported"),
        error.FailedMemoryMap => @panic("Failed to map memory"),
        error.TooManyEntries => @panic("Too many memory maps"),
    };

    for (memory_map) |mem_entry| {
        console.print("Base: 0x{x: <8} | Length: 0x{x: <8} | Type: {s}\n", .{ mem_entry.base, mem_entry.length, @tagName(mem_entry.type) });
    }

    @panic("Entry 2");
}

pub const panic = std.debug.FullPanic(fail);
fn fail(msg: []const u8, _: ?usize) noreturn {
    console.printString("Maize [ ");
    console.setColor(.light_red, .black);
    console.printString("PANIC");
    console.setColor(.light_gray, .black);
    console.printString(" ]: ");
    console.printString(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
