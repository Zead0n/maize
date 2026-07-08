const std = @import("std");
const maize = @import("maize");
const a20 = @import("common/a20.zig");
const cpu = @import("common/cpu.zig");
const gdt = @import("common/gdt.zig");
const vbe = @import("common/vbe.zig");
const vga = @import("common/vga.zig");

const BIOS_FIRM = maize.BootFirm{
    .init = biosInit,
    .setResolution = vbe.setResolution,
};

fn biosInit() anyerror!void {
    vga.clear();

    try a20.enable();

    const required_features =
        @intFromEnum(cpu.Feature.fpu) |
        @intFromEnum(cpu.Feature.pse) |
        @intFromEnum(cpu.Feature.pge) |
        @intFromEnum(cpu.Feature.fxsr);
    if (cpu.cpuid() & required_features != required_features) @panic("Missing required cpu features");
}

export fn _start() linksection(".text.entry") callconv(.naked) noreturn {
    asm volatile (
        \\.code16
        \\    cli
        \\    lgdtw gdtr
        \\    mov %%cr0, %%eax
        \\    or $1, %%al
        \\    mov %%eax, %%cr0
        \\    ljmp %[code_32], $pmode
        \\.code32
        \\pmode:
        \\    mov %[data_32], %%ax
        \\    mov %%ax, %%ds
        \\    mov %%ax, %%es
        \\    mov %%ax, %%fs
        \\    mov %%ax, %%gs
        \\    mov %%ax, %%ss
        \\    jmp %[stage2:a]
        :
        : [code_32] "i" (comptime gdt.descriptorSegment(.Code32)),
          [data_32] "i" (comptime gdt.descriptorSegment(.Data32)),
          [stage2] "X" (&secondStage),
    );
}

fn secondStage(drive: u8) callconv(.{ .x86_sysv = .{} }) noreturn {
    _ = drive;

    maize.run(BIOS_FIRM);

    @panic("Entry 2");
}

pub const panic = std.debug.FullPanic(panicFn);
fn panicFn(msg: []const u8, _: ?usize) noreturn {
    vga.printString("Maize [ ");
    vga.setColor(.light_red, .black);
    vga.printString("PANIC");
    vga.setColor(.light_gray, .black);
    vga.printString(" ]: ");
    vga.printString(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}
