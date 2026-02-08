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

    const bios_disect_step = b.step("bios-disect", "Disect bios stages");
    const bios_install_dir = std.Build.InstallDir{ .custom = "bios" };
    const stage1_install = b.addInstallFileWithDir(bios_stages.stage_one.getEmittedBin(), bios_install_dir, "stage1.elf");
    const stage2_install = b.addInstallFileWithDir(bios_stages.stage_two.getEmittedBin(), bios_install_dir, "stage2.elf");
    bios_disect_step.dependOn(&stage1_install.step);
    bios_disect_step.dependOn(&stage2_install.step);

    const bios_qemu_step = b.step("bios-qemu", "Build bios and run qemu");
    const bios_qemu_cmd = qemu_util.createQemuCommand(b, bios_bootloader.source, arch.toStdArch());
    bios_qemu_cmd.step.dependOn(&bios_bootloader.step);
    bios_qemu_step.dependOn(&bios_qemu_cmd.step);
}
