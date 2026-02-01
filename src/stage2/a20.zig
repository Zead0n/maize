const sys = @import("sys.zig");

pub fn check() bool {
    const boot_id_addr = 0x7dfe;
    const compare_addr = 0x7dfe + 0x100000;

    const original = sys.mem_inw(0x7dfe);
    defer sys.mem_outw(boot_id_addr, original);

    sys.mem_outw(boot_id_addr, 0x1234);
    if (sys.mem_inw(boot_id_addr) != sys.mem_inw(compare_addr))
        return true;

    sys.mem_outw(boot_id_addr, ~sys.mem_inw(boot_id_addr));
    if (sys.mem_inw(boot_id_addr) != sys.mem_inw(compare_addr))
        return true;

    return false;
}

pub fn enable() bool {
    if (check())
        return true;

    asm volatile ("int $0x15"
        :
        : [a] "{ax}" (0x2401),
    );

    if (check())
        return true;

    var byte = sys.inb(0x92);
    if ((byte & 0x02) == 0) {
        byte |= 0x02;
        byte &= ~0x01;
        sys.outb(0x92, byte);
    }

    return check();
}
