// NOTE: zig 0.16.0 has removed the `code16` so this code is unusable for the time being.

const std = @import("std");

const STAGE_TWO_DEST = 0xf000;

pub const DiskAddressPacket = packed struct {
    size: u8 = 0x10,
    reserved: u8 = 0,
    blocks: u16,
    offset: u16,
    segment: u16,
    lba: u64,

    pub fn read(self: @This(), disk: u16) error{ReadFailed}!void {
        const result: u16 = asm volatile (
            \\int $0x13
            : [ret] "={ax}" (-> u16),
            : [ax] "{ax}" (0x4200),
              [disk_num] "{dx}" (disk),
              [dap_addr] "{si}" (&self),
        );

        if (@as(u8, @truncate(result)) != 0)
            return error.ReadFailed;
    }
};

pub fn checkExt13(drive_num: u16) bool {
    var result: u16 = undefined;
    asm (
        \\int $0x13
        : [ret] "={bx}" (result),
        : [func] "{ax}" (0x4100),
          [magic] "{bx}" (0x55aa),
          [drive] "{dx}" (drive_num),
    );

    return result == 0xaa55;
}

fn puts(chars: []const u8) void {
    for (chars) |char|
        asm volatile (
            \\int $0x10
            :
            : [ax] "{ax}" (0x0e00 | @as(u16, char)),
        );
}

export var drive: u16 = 0;
export fn firstStage() noreturn {
    if (!checkExt13(drive)) @panic("E");

    const dap: DiskAddressPacket = .{
        .lba = 1,
        .blocks = 63,
        .offset = 0,
        .segment = (STAGE_TWO_DEST >> 4),
    };

    dap.read(drive) catch @panic("R");

    asm volatile (
        \\push %%dx
        \\calll %[stage2_addr:c]
        :
        : [drive] "{dx}" (drive),
          [stage2_addr] "i" (STAGE_TWO_DEST),
    );

    @panic("1");
}

pub const panic = std.debug.FullPanic(rmPanic);
fn rmPanic(msg: []const u8, _: ?usize) noreturn {
    puts("! ");
    puts(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
