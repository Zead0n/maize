pub fn enable_int() void {
    asm volatile ("sti");
}

pub fn disable_int() void {
    asm volatile ("cli");
}

pub fn outb(port: u16, value: u8) void {
    asm volatile ("outb %%al, %[port]"
        :
        : [a] "{ax}" (value),
          [port] "X" (port),
        : .{ .memory = true });
}

pub fn outw(port: u16, value: u16) void {
    asm volatile ("outw %%ax, %[port]"
        :
        : [a] "{ax}" (value),
          [port] "X" (port),
        : .{ .memory = true });
}

pub fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %%al"
        : [ret] "={ax}" (-> u8),
        : [port] "X" (port),
        : .{ .memory = true });
}

pub fn inw(port: u16) u16 {
    return asm volatile ("inw %[port], %%ax"
        : [ret] "={ax}" (-> u16),
        : [port] "X" (port),
        : .{ .memory = true });
}

pub fn mem_outw(segment: u16, offset: u16, value: u16) void {
    asm volatile (
        \\movw %[segment], %%fs
        \\movw %[value], %%fs:(%[offset:c])
        :
        : [segment] "{ax}" (segment),
          [offset] "i" (offset),
          [value] "ir" (value),
        : .{ .memory = true });
}

pub fn mem_inw(segment: u16, offset: u16) u16 {
    return asm volatile (
        \\movw %[segment], %%fs
        \\movw %%fs:(%[offset:c]), %[ret]
        : [ret] "=r" (-> u16),
        : [segment] "{ax}" (segment),
          [offset] "i" (offset),
        : .{ .memory = true });
}
