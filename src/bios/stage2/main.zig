const std = @import("std");
const a20 = @import("a20.zig");
const cpu = @import("cpu.zig");
const gdt = @import("gdt.zig");
const memmap = @import("memmap.zig");
const mode = @import("mode.zig");
const vga = @import("vga.zig");

const STAGE3_DEST = 0x2000;
const GDT = [_]gdt.GlobalDescriptorEntry{
    gdt.NULL_DESCRIPTOR,
    gdt.KERNEL_CODE_SEGMENT_32,
    gdt.KERNEL_DATA_SEGMENT_32,
};

export fn _start() callconv(.naked) noreturn {
    asm volatile ("jmp %[stage2_entry:a]"
        :
        : [stage2_entry] "X" (&stageTwoEntry),
    );
}

fn stageTwoEntry() callconv(.c) noreturn {
    a20.enable() catch @panic("Could not enable A20 line");
    gdt.load_gdt(@constCast(&GDT));
    mode.enableUnreal();
    vga.clear();

    const fpu_feature = (1 << 0);
    const pae_feature = (1 << 6);
    const pge_feature = (1 << 13);
    const fxsr_feature = (1 << 24);
    const required_cpu_features = fpu_feature | pae_feature | pge_feature | fxsr_feature;
    if (cpu.cpuidFeatures() & required_cpu_features != required_cpu_features)
        @panic("CPU missing required features");

    loadStage3();
    mode.enablePmode();
    asm volatile (
        \\ljmp $0x8, $1f
        \\.code32
        \\1:
        \\  mov $0x10, %%eax
        \\  mov %%eax, %%ds
        \\  mov %%eax, %%es
        \\  mov %%eax, %%ss
        \\  call %[stage3_addr:c]
        \\  hlt
        \\.code16
        :
        : [stage3_addr] "i" (STAGE3_DEST),
    );

    @panic("Entry 2");
}

fn loadStage3() void {
    const stage3_data = @embedFile("stage3");

    var reader = std.Io.Reader.fixed(stage3_data);
    var dest: [*]u8 = @ptrFromInt(STAGE3_DEST);

    var i: usize = 0;
    while (reader.takeByte()) |byte| : (i += 1) {
        dest[i] = byte;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => {}, // TODO: Implement panic when error other than 'EndOfStream' occurs
    }
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
