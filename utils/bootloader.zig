const std = @import("std");
const dd_util = @import("dd.zig");

const BuildOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

pub fn buildStage1(b: *std.Build, options: BuildOptions) *std.Build.Step.Compile {
    const first_stage_dir = b.path("src/stage1");

    const first_stage_mod = b.createModule(.{
        .target = options.target,
        .optimize = options.optimize,
        .root_source_file = first_stage_dir.path(b, "decompress.zig"),
    });
    first_stage_mod.addAssemblyFile(first_stage_dir.path(b, "boot.S"));

    const first_stage_bin = b.addExecutable(.{
        .name = "stage1.bin",
        .root_module = first_stage_mod,
    });
    first_stage_bin.setLinkerScript(first_stage_dir.path(b, "link_stage1.ld"));

    return first_stage_bin;
}

pub fn buildStageTwo(b: *std.Build, options: BuildOptions) *std.Build.Step.Compile {
    const second_stage_dir = b.path("src/stage2");

    const second_stage_mod = b.createModule(.{
        .target = options.target,
        .optimize = options.optimize,
        .root_source_file = second_stage_dir.path(b, "main.zig"),
    });

    const second_stage_bin = b.addExecutable(.{
        .name = "stage2.bin",
        .root_module = second_stage_mod,
    });
    second_stage_bin.setLinkerScript(second_stage_dir.path(b, "link_stage2.ld"));

    return second_stage_bin;
}

pub fn buildBootloader(b: *std.Build, first_stage: *std.Build.Step.Compile, second_stage: *std.Build.Step.Compile) *std.Build.Step.InstallFile {
    const boot_files = b.addWriteFiles();
    const boot_img = boot_files.add("boot.img", "");

    const first_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = first_stage.getEmittedBin(),
        .count = 1,
        .conv = &.{"notrunc"},
    });
    first_dd.step.dependOn(&first_stage.step);

    const second_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = second_stage.getEmittedBin(),
        .seek = 1,
        .count = 7,
        .conv = &.{"notrunc"},
    });
    second_dd.step.dependOn(&second_stage.step);

    const boot_img_install = b.addInstallBinFile(boot_img, "boot.img");
    boot_img_install.step.dependOn(&first_dd.step);
    boot_img_install.step.dependOn(&second_dd.step);

    return boot_img_install;
}
