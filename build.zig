const std = @import("std");
const Architecture = @import("utils/arch.zig").Architecture;
const Builder = @import("utils/builder.zig").Builder;
const qemu_util = @import("utils/qemu.zig");

pub fn build(b: *std.Build) void {
    const arch = b.option(Architecture, "arch", "Cpu architecture (defaults to x86)") orelse Architecture.x86;
    const optimize = b.standardOptimizeOption(.{});

    const builder = Builder{
        .target = b.resolveTargetQuery(arch.getTargetQuery()),
        .optimize = optimize,
    };

    // bootloader step
    const bootloader_step = b.step("bootloader", "Build the bootloader");
    const bootloader = builder.buildBootloader(b);
    const bootloader_install = b.addInstallBinFile(bootloader.getEmittedBin(), bootloader.name);
    bootloader_step.dependOn(&bootloader_install.step);

    // qemu step
    const qemu_step = b.step("qemu", "Build and run bootloader in qemu");
    qemu_step.dependOn(&bootloader.step);
    const qemu_cmd = qemu_util.createQemuCommand(b, bootloader);
    qemu_step.dependOn(&qemu_cmd.step);

    // install step
    const install_step = b.getInstallStep();
    install_step.dependOn(&bootloader_install.step);
}
