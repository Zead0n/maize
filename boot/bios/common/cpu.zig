pub const Feature = enum(u32) {
    fpu = 1 << 0,
    vme = 1 << 1,
    de = 1 << 2,
    pse = 1 << 3,
    tsc = 1 << 4,
    msr = 1 << 5,
    pae = 1 << 6,
    mce = 1 << 7,
    cx8 = 1 << 8,
    apic = 1 << 9,
    sep = 1 << 11,
    mtrr = 1 << 12,
    pge = 1 << 13,
    mca = 1 << 14,
    cmov = 1 << 15,
    pat = 1 << 16,
    pse36 = 1 << 17,
    psn = 1 << 18,
    clflush = 1 << 19,
    ds = 1 << 21,
    acpi = 1 << 22,
    mmx = 1 << 23,
    fxsr = 1 << 24,
    sse = 1 << 25,
    sse2 = 1 << 26,
    ss = 1 << 27,
    htt = 1 << 28,
    tm = 1 << 29,
    ia64 = 1 << 30,
    pbe = 1 << 31,
};

pub fn cpuidFeatures() u32 {
    return asm ("cpuid"
        : [ret] "={edx}" (-> u32),
        : [a] "{eax}" (1),
    );
}
