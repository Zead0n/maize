const cpu = @import("cpu.zig");

pub fn enable() error{FailedA20}!void {
    if (check()) return;

    asm volatile ("int $0x15"
        :
        : [a] "{ax}" (0x2401),
    );

    if (check()) return;

    kbc_enable: {
        cpu.disable_int();
        defer cpu.enable_int();

        if (!kbc_wait(2, 0)) break :kbc_enable;
        cpu.outb(0x64, 0xad);
        if (!kbc_wait(2, 0)) break :kbc_enable;
        cpu.outb(0x64, 0xd0);
        if (!kbc_wait(1, 1)) break :kbc_enable;
        const kbc_byte = cpu.inb(0x60);
        if (!kbc_wait(2, 0)) break :kbc_enable;
        cpu.outb(0x64, 0xd1);
        if (!kbc_wait(2, 0)) break :kbc_enable;
        cpu.outb(0x64, kbc_byte | 2);
        if (!kbc_wait(2, 0)) break :kbc_enable;
        cpu.outb(0x64, 0xae);
    }

    if (check()) return;

    var fast_byte = cpu.inb(0x92);
    if ((fast_byte & 0x02) == 0) {
        fast_byte |= 0x02;
        fast_byte &= 0xfe;
        cpu.outb(0x92, fast_byte);
    }

    if (check()) return;

    return error.FailedA20;
}

fn check() bool {
    const original = cpu.mem_inw(0, 0x7dfe);
    defer cpu.mem_outw(0, 0x7dfe, original);

    cpu.mem_outw(0, 0x7dfe, 0x1234);
    if (cpu.mem_inw(0, 0x7dfe) != cpu.mem_inw(0xffff, 0x7e0e))
        return true;

    cpu.mem_outw(0, 0x7dfe, ~cpu.mem_inw(0, 0x7dfe));
    if (cpu.mem_inw(0, 0x7dfe) != cpu.mem_inw(0xffff, 0x7e0e))
        return true;

    return false;
}

fn kbc_wait(mask: u8, expected: u8) bool {
    const timeout = 50000;
    for (0..timeout) |_| {
        if ((cpu.inb(0x64) & mask) == expected)
            return true;
    }

    return false;
}
