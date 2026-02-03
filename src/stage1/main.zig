const std = @import("std");
const dap = @import("dap.zig");
const utils = @import("utils");
const teletype = utils.teletype;

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
    // dap_entry.read(drive) catch @panic("!R");
    if (DAP_ENTRY.read(drive)) |err_code| {
        teletype.put(err_code);
        @panic("!R");
    }

    asm volatile ("jmp %[stage2_addr:a]"
        :
        : [stage2_addr] "i" (STAGE_TWO_DEST),
    );

    asm volatile ("hlt");

    @panic("!1");
}

pub const panic = std.debug.FullPanic(fail);
pub fn fail(msg: []const u8, _: ?usize) noreturn {
    teletype.println(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
