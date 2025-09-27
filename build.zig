const std = @import("std");
const arch_util = @import("utils/arch.zig");
const builder_util = @import("utils/builder.zig");
const qemu_util = @import("utils/qemu.zig");

pub fn build(b: *std.Build) void {
    // Options
    const arch = b.option(arch_util.Architecture, "arch", "Cpu architecture (defaults to x86)") orelse arch_util.Architecture.x86;
    const optimize = b.standardOptimizeOption(.{});

    // Create Builder, it'll keep build.zig concise
    const builder = builder_util.Builder{
        .target = b.resolveTargetQuery(arch.getTargetQuery()),
        .optimize = optimize,
    };

    // Bootloader step
    const bootloader_step = b.step("bootloader", "Build the bootloader");
    const bootloader = builder.buildBootloader(b);
    const bootloader_install = b.addInstallBinFile(bootloader.getEmittedBin(), bootloader.name);
    bootloader_step.dependOn(&bootloader_install.step);

    // Qemu step
    const qemu_step = b.step("qemu", "Build and run bootloader in qemu");
    qemu_step.dependOn(&bootloader.step);
    const qemu_cmd = qemu_util.createQemuCommand(b, bootloader);
    qemu_step.dependOn(&qemu_cmd.step);

    // Install step
    const install_step = b.getInstallStep();
    install_step.dependOn(&bootloader_install.step);
}
