const DapError = error{ReadFailed};

pub const DiskAddressPacket = packed struct {
    size: u8 = 0x10,
    reserved: u8 = 0,
    blocks: u16,
    segment: u16,
    offset: u16,
    lba: u64,

    pub fn read(self: @This(), disk: u16) DapError!void {
        var out: u16 = undefined;
        asm volatile (
            \\mov (%[dap_addr:P]), %%si
            \\int $0x13
            : [ret] "={ax}" (out),
            : [ax] "{ax}" (0x4200),
              [disk_num] "{dx}" (disk),
              [dap_addr] "X" (&self),
        );

        if (@as(u8, @truncate(out)) != 0) {
            return error.ReadFailed;
        }
    }
};
