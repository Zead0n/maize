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

    // const stages_dir: std.Build.InstallDir = .{ .custom = "stages" };
    // const stages_install_dir: std.Build.Step.InstallArtifact.Options = .{
    //     .dest_dir = .{
    //         .override = stages_dir,
    //     },
    // };
    //
    // const stage1_elf = bootloader_util.buildStageOne(b, .{
    //     .target = b.resolveTargetQuery(arch.getTargetQuery(.code16)),
    //     .optimize = .ReleaseSmall,
    // });
    // const stage1_bin = b.addObjCopy(stage1_elf.getEmittedBin(), .{ .format = .bin });
    // stage1_bin.step.dependOn(&stage1_elf.step);
    //
    // const stage2_elf = bootloader_util.buildStageTwo(b, .{
    //     .target = b.resolveTargetQuery(arch.getTargetQuery(.code16)),
    //     .optimize = .ReleaseSmall,
    // });
    // const stage2_bin = b.addObjCopy(stage2_elf.getEmittedBin(), .{ .format = .bin });
    // stage2_bin.step.dependOn(&stage2_elf.step);
    //
    // const bootloader = bootloader_util.buildBootloader(b, .{
    //     .first = stage1_bin.getOutput(),
    //     .second = stage2_bin.getOutput(),
    // });
    // bootloader.step.dependOn(&stage1_bin.step);
    // bootloader.step.dependOn(&stage2_bin.step);

    // Stages step
    // const stages_step = b.step("stages", "Build only the stages, not the whole bootloader");
    //
    // const stage1_elf_install = b.addInstallArtifact(stage1_elf, stages_install_dir);
    // const stage2_elf_install = b.addInstallArtifact(stage2_elf, stages_install_dir);
    // const stage1_bin_install = b.addInstallFileWithDir(stage1_bin.getOutput(), stages_dir, "stage1.bin");
    // const stage2_bin_install = b.addInstallFileWithDir(stage2_bin.getOutput(), stages_dir, "stage2.bin");
    // stages_step.dependOn(&stage1_elf_install.step);
    // stages_step.dependOn(&stage2_elf_install.step);
    // stages_step.dependOn(&stage1_bin_install.step);
    // stages_step.dependOn(&stage2_bin_install.step);

    // Qemu step
    // const qemu_step = b.step("qemu", "Build and run bootloader in qemu");
    // const qemu_cmd = qemu_util.createQemuCommand(b, bootloader.source, arch.toStdArch());
    // qemu_cmd.step.dependOn(&bootloader.step);
    // qemu_step.dependOn(&qemu_cmd.step);

    // Install step
    // const install_step = b.getInstallStep();
    // install_step.dependOn(&bootloader.step);
}
