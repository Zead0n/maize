pub fn outb(port: u16, value: u8) void {
    asm volatile ("outb %%al, %[port]"
        :
        : [a] "{ax}" (value),
          [port] "X" (port),
    );
}

pub fn outw(port: u16, value: u16) void {
    asm volatile ("outw %%al, %[port]"
        :
        : [a] "{ax}" (value),
          [port] "X" (port),
    );
}

pub fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %%al"
        : [ret] "={ax}" (-> u8),
        : [port] "X" (port),
    );
}

pub fn inw(port: u16) u16 {
    return asm volatile ("inb %[port], %%al"
        : [ret] "={ax}" (-> u16),
        : [port] "X" (port),
    );
}

pub fn mem_outw(addr: usize, value: u16) void {
    asm volatile ("movw %[value], (%[addr:a])"
        :
        : [addr] "r" (addr),
          [value] "ir" (value),
        : .{ .memory = true });
}

pub fn mem_inw(addr: usize) u16 {
    return asm volatile ("movw (%[addr:a]), %[ret]"
        : [ret] "=r" (-> u16),
        : [addr] "X" (addr),
    );
}
