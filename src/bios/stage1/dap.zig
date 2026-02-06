const DapError = error{ReadFailed};

pub const DiskAddressPacket = packed struct {
    size: u8 = 0x10,
    reserved: u8 = 0,
    blocks: u16,
    offset: u16,
    segment: u16,
    lba: u64,

    pub fn read(self: @This(), disk: u16) ?u8 {
        var out: u16 = undefined;
        asm volatile (
            \\mov %[dap_addr], %%esi
            \\int $0x13
            : [ret] "={ax}" (out),
            : [ax] "{ax}" (0x4200),
              [disk_num] "{dx}" (disk),
              [dap_addr] "X" (@intFromPtr(&self)),
        );

        const result: u8 = @as(u8, @truncate(out >> 8));
        return if (result != 0) result else null;
    }
};

pub fn check_ext13(drive: u16) bool {
    var res: u16 = undefined;
    asm (
        \\int $0x13
        : [ret] "={bx}" (res),
        : [func] "{ax}" (0x4100),
          [magic] "{bx}" (0x55aa),
          [drive] "{dx}" (drive),
    );

    return res == 0xaa55;
}
