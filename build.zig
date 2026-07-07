const std = @import("std");
const arch = @import("build/arch.zig");
const bios = @import("build/bios.zig");
const qemu = @import("build/commands/qemu.zig");

pub fn build(b: *std.Build) void {
    const arch_opt = b.option(arch.Architecture, "arch", "Cpu architecture (defaults to x86)") orelse .x86;

    const stages = bios.buildBiosStages(b, arch_opt);
    const bios_bootloader = bios.buildBiosBootloader(
        b,
        b.fmt("maize-bios-{s}.img", .{@tagName(arch_opt)}),
        stages,
    );

    const bios_step = b.step("bios", "Build bios");
    bios_step.dependOn(&bios_bootloader.step);

    const bios_disect_step = b.step("bios-disect", "Disect bios stages");
    const bios_install_dir = std.Build.InstallDir{ .custom = "bios" };
    const stage1_elf_install = b.addInstallFileWithDir(stages.stage1.getEmittedBin(), bios_install_dir, "stage1.elf");
    const stage1_asm_install = b.addInstallFileWithDir(stages.stage1.getEmittedAsm(), bios_install_dir, "stage1.asm");
    const stage2_elf_install = b.addInstallFileWithDir(stages.stage1.getEmittedBin(), bios_install_dir, "stage2.elf");
    const stage2_asm_install = b.addInstallFileWithDir(stages.stage1.getEmittedAsm(), bios_install_dir, "stage2.asm");
    bios_disect_step.dependOn(&stage1_elf_install.step);
    bios_disect_step.dependOn(&stage1_asm_install.step);
    bios_disect_step.dependOn(&stage2_elf_install.step);
    bios_disect_step.dependOn(&stage2_asm_install.step);

    const bios_qemu_step = b.step("bios-qemu", "Build bios and run qemu");
    const bios_qemu_cmd = qemu.createQemuCommand(b, bios_bootloader.source, arch_opt.toStdArch());
    bios_qemu_cmd.step.dependOn(&bios_bootloader.step);
    bios_qemu_step.dependOn(&bios_qemu_cmd.step);
}
