const std = @import("std");
const disk = @import("common/disk.zig");

const STAGE2_DEST = 0xa000;
const DAP: disk.DiskAddressPacket = .{
    .lba = 1,
    .blocks = 63,
    .offset = 0,
    .segment = (STAGE2_DEST >> 4),
};

pub const panic = std.debug.FullPanic(rmPanic);
fn rmPanic(msg: []const u8, _: ?usize) noreturn {
    put('!');
    for (msg) |char|
        put(char);

    while (true)
        asm volatile ("hlt");

    unreachable;
}

fn put(char: u8) void {
    asm volatile (
        \\int $0x10
        :
        : [ax] "{ax}" (0x0e00 | @as(u16, char)),
    );
}

export fn firstStage() noreturn {
    const drive: u8 = asm (
        \\movb %%dl, %[ret]
        : [ret] "=r" (-> u8),
    );

    DAP.read(drive) catch |err| switch (err) {
        disk.DapError.NotSupported => @panic("E"),
        disk.DapError.ReadFailed => @panic("R"),
    };

    asm volatile (
        \\push %[disk]
        \\jmp %[stage2:a]
        :
        : [disk] "{dx}" (@as(u16, drive)),
          [stage2] "i" (STAGE2_DEST),
    );

    unreachable;
}
