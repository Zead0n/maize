const DapError = error{ReadFailed};

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
