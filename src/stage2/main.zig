const std = @import("std");
const utils = @import("utils");
const a20 = @import("a20.zig");
const memmap = @import("memmap.zig");
const teletype = utils.teletype;

export fn _start() callconv(.naked) noreturn {
    asm volatile ("jmp %[stage2_entry:a]"
        :
        : [stage2_entry] "X" (&stage2_entry),
    );
}

fn stage2_entry() callconv(.c) noreturn {
    a20.enable() catch @panic("Could not enable A20 line");
    _ = memmap.detect_memory() catch |err| switch (err) {
        error.Unsupported => @panic("E820 unsupported"),
        error.FailedMemoryMap => @panic("Failed to map memory"),
        error.TooManyEntries => @panic("Too many memory maps"),
    };

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
