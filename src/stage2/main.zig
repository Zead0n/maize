const std = @import("std");
const utils = @import("utils");
const a20 = @import("a20.zig");
const teletype = utils.teletype;

export fn _start() callconv(.naked) noreturn {
    asm volatile ("jmp %[stage2_entry:a]"
        :
        : [stage2_entry] "X" (&stage2_entry),
    );
}

fn stage2_entry() callconv(.c) noreturn {
    if (!a20.enable()) @panic("Could not enable a20");
}

pub const panic = std.debug.FullPanic(fail);
fn fail(msg: []const u8, _: ?usize) noreturn {
    teletype.puts("MAIZE PANIC: ");
    teletype.println(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
