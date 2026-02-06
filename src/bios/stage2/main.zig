const std = @import("std");
const a20 = @import("a20.zig");
const memmap = @import("memmap.zig");
const teletype = @import("teletype.zig");

export fn _start() callconv(.naked) noreturn {
    asm volatile ("jmp %[stage2_entry:a]"
        :
        : [stage2_entry] "X" (&stage2_entry),
    );
}

fn stage2_entry() callconv(.c) noreturn {
    a20.enable() catch @panic("Could not enable A20 line");
    const memory_map = memmap.detect_memory() catch |err| switch (err) {
        error.Unsupported => @panic("E820 unsupported"),
        error.FailedMemoryMap => @panic("Failed to map memory"),
        error.TooManyEntries => @panic("Too many memory maps"),
    };

    teletype.put(1);
    teletype.put(2);
    teletype.put(' ');

    for (memory_map) |mem_entry| {
        teletype.put(@truncate(@intFromEnum(mem_entry.type)));
    }

    @panic("Entry 2");
}

pub const panic = std.debug.FullPanic(fail);
fn fail(msg: []const u8, _: ?usize) noreturn {
    teletype.puts("Maize [PANIC]: ");
    teletype.println(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
