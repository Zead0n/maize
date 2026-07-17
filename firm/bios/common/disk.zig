pub const DapError = error{ NotSupported, ReadFailed };

pub const DiskAddressPacket = packed struct {
    size: u8 = 0x10,
    reserved: u8 = 0,
    blocks: u16,
    offset: u16,
    segment: u16,
    lba: u64,

    pub fn read(self: @This(), disk: u8) DapError!void {
        const check_value: u16 = asm (
            \\int $0x13
            : [ret] "={bx}" (-> u16),
            : [func] "{ax}" (0x4100),
              [magic] "{bx}" (0x55aa),
              [drive] "{dx}" (disk),
        );

        if (check_value != 0xaa55)
            return DapError.NotSupported;

        const result: u16 = asm (
            \\int $0x13
            : [ret] "={ax}" (-> u16),
            : [ax] "{ax}" (0x4200),
              [disk_num] "{dx}" (disk),
              [dap_addr] "{si}" (&self),
        );

        if (@as(u8, @truncate(result)) != 0)
            return DapError.ReadFailed;
    }
};
