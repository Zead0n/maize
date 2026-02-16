const std = @import("std");
const a20 = @import("a20.zig");
const gdt = @import("gdt.zig");
const mode = @import("mode.zig");
const real = @import("real.zig");
const vga = @import("vga.zig");

export fn _start() linksection(".text.entry") callconv(.naked) noreturn {
    asm volatile (
        \\.code16
        \\cli
        \\lgdtw gdtr
        \\mov %%cr0, %%eax
        \\or $1, %%al
        \\mov %%eax, %%cr0
        \\ljmp %[code_32], $pmode
        \\.code32
        \\pmode:
        \\mov %[data_32], %%ax
        \\mov %%ax, %%ds
        \\mov %%ax, %%es
        \\mov %%ax, %%fs
        \\mov %%ax, %%gs
        \\mov %%ax, %%ss
        \\jmp %[stage2_entry:a]
        :
        : [code_32] "i" (comptime gdt.descriptorSegment(.Code32)),
          [data_32] "i" (comptime gdt.descriptorSegment(.Data32)),
          [stage2_entry] "X" (&stageTwoEntry),
    );
}

fn stageTwoEntry() callconv(.c) noreturn {
    vga.clear();

    a20.enable() catch @panic("Failed to enable A20");

    // thunk.eax = 0x0e43;
    // thunk.int(0x10);
    //
    // vga.print("{*}\n", .{thunk});
    // vga.print("0x{x}\n", .{thunk.eax});

    @panic("Entry 2");
}

pub const panic = std.debug.FullPanic(fail);
fn fail(msg: []const u8, _: ?usize) noreturn {
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
