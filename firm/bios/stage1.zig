const std = @import("std");

pub const DiskAddressPacket = packed struct {
    size: u8 = 0x10,
    reserved: u8 = 0,
    blocks: u16,
    offset: u16,
    segment: u16,
    lba: u64,

    pub fn read(self: @This(), disk: u8) error{ NotSupported, ReadFailed }!void {
        const check_value: u16 = asm (
            \\int $0x13
            : [ret] "={bx}" (-> u16),
            : [func] "{ax}" (0x4100),
              [magic] "{bx}" (0x55aa),
              [drive] "{dx}" (disk),
        );

        if (check_value != 0xaa55)
            return error.NotSupported;

        const result: u16 = asm (
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

const STAGE2_DEST = 0xa000;
const DAP: DiskAddressPacket = .{
    .lba = 1,
    .blocks = 63,
    .offset = 0,
    .segment = (STAGE2_DEST >> 4),
};

export fn firstStage() noreturn {
    const drive: u8 = asm (
        \\movb %%dl, %[ret]
        : [ret] "=r" (-> u8),
    );

    DAP.read(drive) catch |err| switch (err) {
        error.NotSupported => @panic("E"),
        error.ReadFailed => @panic("R"),
    };

    asm volatile (
        \\push %[disk]
        \\calll %[stage2:a]
        :
        : [disk] "{dx}" (@as(u16, drive)),
          [stage2] "i" (STAGE2_DEST),
    );

    @panic("1");
}

fn puts(chars: []const u8) void {
    for (chars) |char|
        asm volatile (
            \\int $0x10
            :
            : [ax] "{ax}" (0x0e00 | @as(u16, char)),
        );
}

pub const panic = std.debug.FullPanic(rmPanic);
fn rmPanic(msg: []const u8, _: ?usize) noreturn {
    puts("!");
    puts(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
