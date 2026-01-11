const console = @import("console.zig");

export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\jmp %[stage2_entry:P]
        :
        : [stage2_entry] "X" (&stage2_entry),
    );

    unreachable;
}

noinline fn stage2_entry() callconv(.c) noreturn {
    console.clear();
    console.printString("Hello maize");

    while (true)
        asm volatile ("hlt");

    unreachable;
}
