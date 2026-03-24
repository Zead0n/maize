pub fn put(char: u8) void {
    asm volatile (
        \\int $0x10
        :
        : [ax] "{ax}" (0x0e00 | @as(u16, char)),
    );
}

pub fn puts(chars: []const u8) void {
    for (chars) |char|
        put(char);
}

pub fn println(chars: []const u8) void {
    puts(chars);
    puts("\n\r");
}
