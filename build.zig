const std = @import("std");
const arch_util = @import("build/arch.zig");
const bootloader_util = @import("build/bootloader.zig");
const qemu_util = @import("build/commands/qemu.zig");

pub fn build(b: *std.Build) void {
    const arch = b.option(arch_util.Architecture, "arch", "Cpu architecture (defaults to x86)") orelse arch_util.Architecture.x86;
    const target_query = b.resolveTargetQuery(arch.getTargetQuery());
    const stages_install_dir: std.Build.Step.InstallArtifact.Options = .{
        .dest_dir = .{
            .override = .{ .custom = "stages" },
        },
    };

    const stage1 = bootloader_util.buildStage1(b, .{
        .target = target_query,
        .optimize = .ReleaseSmall,
    });

    const true_stage1 = b.addObjCopy(stage1.getEmittedBin(), .{
        .format = .bin,
    });

    const stage2 = bootloader_util.buildStageTwo(b, .{
        .target = target_query,
        .optimize = .ReleaseSmall,
    });

    const decompress = bootloader_util.buildDecompress(b, stage2, .{
        .target = target_query,
        .optimize = .ReleaseSmall,
    });

    const bootloader = bootloader_util.buildBootloader(b, .{
        .first = stage1,
        .decompress = decompress,
        .second = stage2,
    });

    // Stages step
    const stages_step = b.step("stages", "Build only the stages, not the whole bootloader");

    const stage1_install = b.addInstallArtifact(stage1, stages_install_dir);
    const true_stage1_install = b.addInstallFileWithDir(true_stage1.getOutput(), .{ .custom = "stages" }, "true_stage1.bin");
    const decompress_install = b.addInstallArtifact(decompress, stages_install_dir);
    const stage2_install = b.addInstallArtifact(stage2, stages_install_dir);
    stages_step.dependOn(&stage1_install.step);
    stages_step.dependOn(&true_stage1_install.step);
    stages_step.dependOn(&decompress_install.step);
    stages_step.dependOn(&stage2_install.step);

    // Qemu step
    const qemu_step = b.step("qemu", "Build and run bootloader in qemu");
    const qemu_cmd = qemu_util.createQemuCommand(b, bootloader.source, arch.toStdArch());
    qemu_cmd.step.dependOn(&bootloader.step);
    qemu_step.dependOn(&qemu_cmd.step);

    // Install step
    const install_step = b.getInstallStep();
    install_step.dependOn(&bootloader.step);
}
