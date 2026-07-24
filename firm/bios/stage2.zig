const std = @import("std");
const maize = @import("maize");
const a20 = @import("common/a20.zig");
const cpu = @import("common/cpu.zig");
const gdt = @import("common/gdt.zig");
const vbe = @import("common/vbe.zig");
const vga = @import("common/vga.zig");
const console = @import("console.zig");
const color = @import("common/color.zig");

const VgaColor = color.VgaColor;

const term = &console.term;

// Root declarations

pub const std_options: std.Options = .{
    .logFn = biosLogFn,
};

fn biosLogFn(
    comptime level: std.log.Level,
    comptime _: @EnumLiteral(),
    comptime fmt: []const u8,
    args: anytype,
) void {
    term.print(" [");

    switch (level) {
        .debug => {
            term.setColor(VgaColor.light_cyan.toArgb(), VgaColor.black.toArgb());
            term.print("DBUG");
        },
        .info => {
            term.setColor(VgaColor.light_blue.toArgb(), VgaColor.black.toArgb());
            term.print("INFO");
        },
        .warn => {
            term.setColor(VgaColor.light_magenta.toArgb(), VgaColor.black.toArgb());
            term.print("WARN");
        },
        .err => {
            term.setColor(VgaColor.light_red.toArgb(), VgaColor.black.toArgb());
            term.print("ERR ");
        },
    }

    term.setColor(VgaColor.light_gray.toArgb(), VgaColor.black.toArgb());
    term.print("]: ");
    term.print(fmt, args);
    term.printChar('\n');
}

pub const panic = std.debug.FullPanic(panicFn);
fn panicFn(msg: []const u8, _: ?usize) noreturn {
    term.print("[");
    term.setColor(VgaColor.red.toArgb(), VgaColor.black.toArgb());
    term.print("PANIC");
    term.setColor(VgaColor.light_gray.toArgb(), VgaColor.black.toArgb());
    term.print("]: ");
    term.print(msg);

    while (true)
        asm volatile ("hlt");

    unreachable;
}

// Bios firm

const bios_firm = maize.Firm{
    .init = init,
};

const REQUIRED_FEATURES: u32 =
    @intFromEnum(cpu.Feature.fpu) |
    @intFromEnum(cpu.Feature.pse) |
    @intFromEnum(cpu.Feature.pge) |
    @intFromEnum(cpu.Feature.fxsr);

fn init() !void {}

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
    a20.enable() catch @panic("Enabling A20 failed.");

    if (cpu.cpuid() & REQUIRED_FEATURES != REQUIRED_FEATURES)
        @panic("Missing necessary CPU features.");

    term.clear();
    term.print("Hello from maize\n");

    // maize.run(&bios_firm) catch |e| @panic(@errorName(e));

    @panic("Entry 2");
}
