const std = @import("std");
const dap = @import("dap.zig");
const teletype = @import("teletype.zig");

const STAGE_TWO_DEST = 0x8000;
const DAP_ENTRY: dap.DiskAddressPacket = .{
    .lba = 1,
    .blocks = 7,
    .offset = 0,
    .segment = (STAGE_TWO_DEST >> 4),
};

export var drive: u8 = 0;

export fn first_stage() noreturn {
    if (!dap.check_ext13(drive)) @panic("!E");
    DAP_ENTRY.read(drive) catch @panic("!R");

    asm volatile ("jmp %[stage2_addr:a]"
        :
        : [stage2_addr] "i" (STAGE_TWO_DEST),
    );

    @panic("!1");
}

pub const panic = std.debug.FullPanic(fail);
pub fn fail(msg: []const u8, _: ?usize) noreturn {
    teletype.println(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
