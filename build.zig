const std = @import("std");
const Architecture = @import("utils/arch.zig").Architecture;
const Builder = @import("utils/builder.zig").Builder;

pub fn build(b: *std.Build) void {
    const arch = b.option(Architecture, "arch", "Cpu architecture (defaults to x86)") orelse Architecture.x86;
    const optimize = b.standardOptimizeOption(.{});

    const builder = Builder{
        .target = b.resolveTargetQuery(arch.getTargetQuery()),
        .optimize = optimize,
    };

    const bootloader = builder.buildBootloader(b);

    const bootloader_install = b.addInstallBinFile(bootloader.getEmittedBin(), bootloader.name);

    // install step
    const install_step = b.getInstallStep();
    install_step.dependOn(&bootloader_install.step);
}
