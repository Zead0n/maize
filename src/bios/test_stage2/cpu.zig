pub fn cpuidFeatures() u32 {
    return asm ("cpuid"
        : [ret] "={edx}" (-> u32),
        : [a] "{eax}" (1),
    );
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

pub fn memIn(comptime T: type, addr: usize) T {
    const instruction = comptime switch (T) {
        u8 => "movb %[addr:a], %[ret]",
        u16 => "movw %[addr:a], %[ret]",
        else => @compileError("Unsupported type"),
    };

    return asm (instruction
        : [ret] "=r" (-> T),
        : [addr] "i" (addr),
        : .{ .memory = true });
}

pub fn memOut(comptime T: type, addr: usize, value: T) void {
    const instruction = comptime switch (T) {
        u8 => "movb %[value], %[addr:a]",
        u16 => "movw %[value], %[addr:a]",
        else => @compileError("Unsupported type"),
    };

    asm volatile (instruction
        :
        : [addr] "i" (addr),
          [value] "ir" (value),
        : .{ .memory = true });
}
