const std = @import("std");
const arch_util = @import("arch.zig");
const dd_util = @import("commands/dd.zig");
const gzip_util = @import("commands/gzip.zig");

pub const BiosStages = struct {
    stage1: *std.Build.Step.Compile,
    stage2: *std.Build.Step.Compile,
};

pub fn buildBiosStages(b: *std.Build, arch: arch_util.Architecture) BiosStages {
    const bios_dir = b.path("boot/bios");

    // Stage1
    const stage1_mod = b.createModule(.{
        .target = b.resolveTargetQuery(arch.getTargetQuery(.code16)),
        .optimize = .ReleaseSmall,
        .root_source_file = bios_dir.path(b, "stage1/main.zig"),
    });
    stage1_mod.addAssemblyFile(bios_dir.path(b, "stage1/entry.S"));

    const stage1_elf = b.addExecutable(.{
        .name = "stage1.elf",
        .root_module = stage1_mod,
    });
    stage1_elf.setLinkerScript(bios_dir.path(b, "stage1/link_stage1.ld"));

    // Stage2
    const stage2_mod = b.createModule(.{
        .target = b.resolveTargetQuery(arch.getTargetQuery(.none)),
        .optimize = .ReleaseSmall,
        .root_source_file = bios_dir.path(b, "test_stage2/main.zig"),
    });
    stage2_mod.addAssemblyFile(bios_dir.path(b, "test_stage2/real.S"));

    const stage2_elf = b.addExecutable(.{
        .name = "stage2.elf",
        .root_module = stage2_mod,
    });
    stage2_elf.setLinkerScript(bios_dir.path(b, "test_stage2/link_stage2.ld"));

    return .{
        .stage1 = stage1_elf,
        .stage2 = stage2_elf,
    };
}

pub fn buildBiosBootloader(b: *std.Build, name: []const u8, stages: BiosStages) *std.Build.Step.InstallFile {
    const stage1_bin = b.addObjCopy(stages.stage1.getEmittedBin(), .{
        .basename = "stage1.bin",
        .format = .bin,
    });
    stage1_bin.step.dependOn(&stages.stage1.step);

    const stage2_bin = b.addObjCopy(stages.stage2.getEmittedBin(), .{
        .basename = "stage2.bin",
        .format = .bin,
    });
    stage2_bin.step.dependOn(&stages.stage2.step);

    // Bios Bootloader Image
    const boot_files = b.addWriteFiles();
    const boot_img = boot_files.add("boot.img", "");

    const init_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = std.Build.LazyPath{ .cwd_relative = "/dev/zero" },
        .count = 2048,
        .conv = &.{ "notrunc", "sync" },
    });

    const first_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = stage1_bin.getOutput(),
        .count = 1,
        .conv = &.{ "notrunc", "sync" },
    });
    first_dd.step.dependOn(&stage1_bin.step);

    const second_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = stage2_bin.getOutput(),
        .seek = 1,
        .count = 2047,
        .conv = &.{ "notrunc", "sync" },
    });
    second_dd.step.dependOn(&stage2_bin.step);

    const bootloader = b.addInstallBinFile(boot_img, name);
    bootloader.step.dependOn(&init_dd.step);
    bootloader.step.dependOn(&first_dd.step);
    bootloader.step.dependOn(&second_dd.step);

    return bootloader;
}
