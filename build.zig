const std = @import("std");
const arch_util = @import("build/arch.zig");
const bootloader_util = @import("build/bootloader.zig");
const qemu_util = @import("build/commands/qemu.zig");

pub fn build(b: *std.Build) void {
    const arch = b.option(arch_util.Architecture, "arch", "Cpu architecture (defaults to x86)") orelse .x86;

    const bios_stages = bootloader_util.buildBiosStages(b, arch);
    const bios_bootloader = bootloader_util.buildBiosBootloader(
        b,
        b.fmt("maize-bios-{s}.img", .{@tagName(arch)}),
        bios_stages,
    );

    const bios_step = b.step("bios", "Build bios");
    bios_step.dependOn(&bios_bootloader.step);

    const qemu_bios_step = b.step("qemu-bios", "Build bios and run qemu");
    const qemu_bios_cmd = qemu_util.createQemuCommand(b, bios_bootloader.source, arch.toStdArch());
    qemu_bios_cmd.step.dependOn(&bios_bootloader.step);
    qemu_bios_step.dependOn(&qemu_bios_cmd.step);
}
