const std = @import("std");
const vga = @import("vga.zig");

export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\jmp %[stage3Entry:a]
        :
        : [stage3Entry] "X" (&stageThreeEntry),
    );
}

fn stageThreeEntry() noreturn {
    @panic("Stage 3 entry");
}

pub const panic = std.debug.FullPanic(fail);
fn fail(msg: []const u8, _: ?usize) noreturn {
    vga.printString("Maize [ ");
    vga.setColor(.light_red, .black);
    vga.printString("PANIC");
    vga.setColor(.light_gray, .black);
    vga.printString(" ]: ");
    vga.printString(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
