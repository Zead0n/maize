const cpu = @import("cpu.zig");
const real = @import("real.zig");

pub fn enable() error{FailedA20}!void {
    if (check()) return;

    const a20_thunk: real.Thunk = .{ .eax = 0x2401 };
    _ = a20_thunk.int(0x15);

    if (check()) return;

    kbc_enable: {
        if (!kbcWait(2, 0)) break :kbc_enable;
        cpu.out(u8, 0x64, 0xad);
        if (!kbcWait(2, 0)) break :kbc_enable;
        cpu.out(u8, 0x64, 0xd0);
        if (!kbcWait(1, 1)) break :kbc_enable;
        const kbc_byte = cpu.in(u8, 0x60);
        if (!kbcWait(2, 0)) break :kbc_enable;
        cpu.out(u8, 0x64, 0xd1);
        if (!kbcWait(2, 0)) break :kbc_enable;
        cpu.out(u8, 0x64, kbc_byte | 2);
        if (!kbcWait(2, 0)) break :kbc_enable;
        cpu.out(u8, 0x64, 0xae);
    }

    if (check()) return;

    var fast_byte = cpu.in(u8, 0x92);
    if ((fast_byte & 0x02) == 0) {
        fast_byte |= 0x02;
        fast_byte &= 0xfe;
        cpu.out(u8, 0x92, fast_byte);
    }

    if (check()) return;

    return error.FailedA20;
}

fn check() bool {
    const boot_id_addr = 0x7dfe;
    const compare_addr = boot_id_addr + 0x100000;

    const original = cpu.memIn(u16, boot_id_addr);
    defer cpu.memOut(u16, boot_id_addr, original);

    cpu.memOut(u16, boot_id_addr, 0x1234);
    if (cpu.memIn(u16, boot_id_addr) != cpu.memIn(u16, compare_addr))
        return true;

    cpu.memOut(u16, boot_id_addr, ~cpu.memIn(u16, boot_id_addr));
    if (cpu.memIn(u16, boot_id_addr) != cpu.memIn(u16, compare_addr))
        return true;

    return false;
}

fn kbcWait(mask: u8, expected: u8) bool {
    const timeout = 50000;
    for (0..timeout) |_| {
        if ((cpu.in(u8, 0x64) & mask) == expected)
            return true;
    }

    return false;
}
