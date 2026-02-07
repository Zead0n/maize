pub fn enable_int() void {
    asm volatile ("sti");
}

pub fn disable_int() void {
    asm volatile ("cli");
}

pub fn in(comptime T: type, port: u16) T {
    const instruction = comptime switch (T) {
        u8 => "inb %[port], %[ret]",
        u16 => "inw %[port], %[ret]",
        else => @compileError("Unsupported type"),
    };

    return asm (instruction
        : [ret] "={ax}" (-> T),
        : [port] "i" (port),
    );
}

pub fn out(comptime T: type, port: u16, value: T) void {
    const instruction = comptime switch (T) {
        u8 => "outb %%al, %[port]",
        u16 => "outw %%ax, %[port]",
        else => @compileError("Unsupported type"),
    };

    asm volatile (instruction
        :
        : [a] "{ax}" (value),
          [port] "X" (port),
        : .{ .memory = true });
}

pub fn memIn(comptime T: type, segment: u16, offset: u16) T {
    const instruction = comptime switch (T) {
        u8 =>
        \\movw %[segment], %%fs
        \\movb %%fs:(%[offset:c]), %[ret]
        ,
        u16 =>
        \\movw %[segment], %%fs
        \\movw %%fs:(%[offset:c]), %[ret]
        ,
        else => @compileError("Unsupported type"),
    };

    return asm (instruction
        : [ret] "=r" (-> T),
        : [segment] "{ax}" (segment),
          [offset] "i" (offset),
        : .{ .memory = true });
}

pub fn memOut(comptime T: type, segment: u16, offset: u16, value: T) void {
    const instruction = comptime switch (T) {
        u8 =>
        \\movw %[segment], %%fs
        \\movb %[value], %%fs:(%[offset:c])
        ,
        u16 =>
        \\movw %[segment], %%fs
        \\movw %[value], %%fs:(%[offset:c])
        ,
        else => @compileError("Unsupported type"),
    };

    asm volatile (instruction
        :
        : [segment] "{ax}" (segment),
          [offset] "i" (offset),
          [value] "ir" (value),
        : .{ .memory = true });
}
