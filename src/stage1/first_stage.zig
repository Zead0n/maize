const std = @import("std");
const utils = @import("utils.zig");
const dap = @import("dap.zig");

const PartitionEntry = packed struct {
    boot_flag: u8,
    begin_head: u8,
    begin_sector: u6,
    begin_cylinder: u10,
    system_id: u8,
    end_head: u8,
    end_sector: u6,
    end_cylinder: u10,
    lba: u32,
    total_sectors: u32,
};

export fn first_stage(drive: u16) noreturn {
    const stage2_dest = 0x8000;
    const dap_entry: dap.DiskAddressPacket = .{
        .lba = 1,
        .blocks = 15,
        .segment = (stage2_dest >> 4),
        .offset = 0,
    };
    dap_entry.read(drive) catch @panic("!R");

    asm volatile ("jmp %[stage2_addr:P]"
        :
        : [stage2_addr] "X" (stage2_dest),
    );

    @panic("!1");

    // const limit: u64 = 0xffff | (0xf << 48);
    // const flags: u64 = (0b1100 << 52);
    // const access: u64 = (0b10010010 << 40);
    // const executable: u64 = (1 << 43);
    //
    // const base_descriptor = limit | flags | access;
    // const gdt_entry = &gdt.Gdt{
    //     .code = base_descriptor | executable,
    //     .data = base_descriptor,
    // };
    //
    // asm volatile ("cli");
    // gdt.load(gdt_entry);
    // gdt.enable_pmode();
}

pub const panic = std.debug.FullPanic(fail);
pub fn fail(msg: []const u8, _: ?usize) noreturn {
    utils.println(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
