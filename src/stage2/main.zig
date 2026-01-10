export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\movw %%ax, (0xb8000)
        :
        : [char] "{ax}" (0x0f5a),
    );

    while (true)
        asm volatile ("hlt");

    unreachable;
}
