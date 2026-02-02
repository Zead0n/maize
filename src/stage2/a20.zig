const cpu = @import("cpu.zig");

pub fn enable() bool {
    if (check())
        return true;

    asm volatile ("int $0x15"
        :
        : [a] "{ax}" (0x2401),
    );

    if (check())
        return true;

    kbc_enable();

    if (check())
        return true;

    var byte = cpu.inb(0x92);
    if ((byte & 0x02) == 0) {
        byte |= 0x02;
        byte &= 0xfe;
        cpu.outb(0x92, byte);
    }

    return check();
}

fn check() bool {
    const original = cpu.mem_inw(0, 0x7dfe);
    defer cpu.mem_outw(0, 0x7dfe, original);

    cpu.mem_outw(0, 0x7dfe, 0x1234);
    if (cpu.mem_inw(0, 0x7dfe) != cpu.mem_inw(0xffff, 0x7e0e))
        return true;

    const flipped_byte = ~cpu.mem_inw(0, 0x7dfe);
    cpu.mem_outw(0, 0x7dfe, flipped_byte);
    if (cpu.mem_inw(0, 0x7dfe) != cpu.mem_inw(0xffff, 0x7e0e))
        return true;

    return false;
}

fn kbc_enable() void {
    cpu.disable_int();
    defer cpu.enable_int();

    if (!kbc_wait(2, 0)) return;
    cpu.outb(0x64, 0xad);
    if (!kbc_wait(2, 0)) return;
    cpu.outb(0x64, 0xd0);
    if (!kbc_wait(1, 1)) return;
    const byte = cpu.inb(0x60);
    if (!kbc_wait(2, 0)) return;
    cpu.outb(0x64, 0xd1);
    if (!kbc_wait(2, 0)) return;
    cpu.outb(0x64, byte | 2);
    if (!kbc_wait(2, 0)) return;
    cpu.outb(0x64, 0xae);
}

fn kbc_wait(m: u8, ex: u8) bool {
    const timeout = 50000;
    for (0..timeout) |_| {
        if ((cpu.inb(0x64) & m) == ex)
            return true;
    }

    return false;
}
