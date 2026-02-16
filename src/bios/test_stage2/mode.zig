pub fn enablePmode() void {
    asm volatile ("cli");
    writeCR0(readCR0() | 1);
}

pub fn disablePmode() void {
    writeCR0(readCR0() & 0xfe);
    asm volatile ("sti");
}

pub fn readCR0() u32 {
    return asm volatile ("mov %%cr0, %[ret]"
        : [ret] "={eax}" (-> u32),
    );
}

pub fn writeCR0(value: u32) void {
    return asm volatile ("mov %[val], %%cr0"
        :
        : [val] "{eax}" (value),
    );
}
