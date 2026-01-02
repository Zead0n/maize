const std = @import("std");
const arch_util = @import("utils/arch.zig");
const bootloader_util = @import("utils/bootloader.zig");
const qemu_util = @import("utils/qemu.zig");

pub fn build(b: *std.Build) void {
    const arch = b.option(arch_util.Architecture, "arch", "Cpu architecture (defaults to x86)") orelse arch_util.Architecture.x86;
    const optimize = b.standardOptimizeOption(.{});

    const stage1 = bootloader_util.buildStage1(b, .{
        .target = b.resolveTargetQuery(arch.getTargetQuery()),
        .optimize = optimize,
    });

    const stage2 = bootloader_util.buildStageTwo(b, .{
        .target = b.resolveTargetQuery(arch.getTargetQuery()),
        .optimize = optimize,
    });

    const bootloader = bootloader_util.buildBootloader(b, stage1, stage2);

    // Bootloader step
    const bootloader_step = b.step("bootloader", "Build the bootloader");
    bootloader_step.dependOn(&bootloader.step);

    // Qemu step
    const qemu_step = b.step("qemu", "Build and run bootloader in qemu");
    const qemu_cmd = qemu_util.createQemuCommand(b, bootloader.source, arch.toStdArch());
    qemu_cmd.step.dependOn(&bootloader.step);
    qemu_step.dependOn(&qemu_cmd.step);

    // Install step
    const install_step = b.getInstallStep();
    install_step.dependOn(&bootloader.step);
    b.installArtifact(stage1);
    b.installArtifact(stage2);
}
