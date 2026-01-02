const std = @import("std");
const dd_util = @import("dd.zig");

const BuildOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

const BootStages = struct {
    first: *std.Build.Step.Compile,
    second: *std.Build.Step.Compile,
    decompress: *std.Build.Step.Compile,
};

pub fn buildStage1(b: *std.Build, options: BuildOptions) *std.Build.Step.Compile {
    const first_stage_dir = b.path("src/stage1");

    const first_stage_mod = b.createModule(.{
        .target = options.target,
        .optimize = options.optimize,
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

pub fn buildDecompress(b: *std.Build, options: BuildOptions) *std.Build.Step.Compile {
    const decompress_dir = b.path("src/decompress");

    const decompress_mod = b.createModule(.{
        .target = options.target,
        .optimize = options.optimize,
        .root_source_file = decompress_dir.path(b, "decompress.zig"),
    });
    decompress_mod.addAssemblyFile(decompress_dir.path(b, "entry.S"));

    const decompress_bin = b.addExecutable(.{
        .name = "decompress.bin",
        .root_module = decompress_mod,
    });
    decompress_bin.setLinkerScript(decompress_dir.path(b, "decompress.ld"));

    return decompress_bin;
}

pub fn buildBootloader(b: *std.Build, stages: BootStages) *std.Build.Step.InstallFile {
    const boot_files = b.addWriteFiles();
    const boot_img = boot_files.add("boot.img", "");

    const first_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = stages.first.getEmittedBin(),
        .count = 1,
        .conv = &.{ "notrunc", "sync" },
    });
    first_dd.step.dependOn(&stages.first.step);

    const decompress_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = stages.decompress.getEmittedBin(),
        .seek = 1,
        .count = 1,
        .conv = &.{ "notrunc", "sync" },
    });
    decompress_dd.step.dependOn(&stages.decompress.step);

    const second_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = stages.second.getEmittedBin(),
        .seek = 2,
        .count = 30,
        .conv = &.{ "notrunc", "sync" },
    });
    second_dd.step.dependOn(&stages.second.step);

    const padding_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = std.Build.LazyPath{ .cwd_relative = "/dev/zero" },
        .seek = 31,
        .count = 1,
        .conv = &.{ "notrunc", "sync" },
    });

    const boot_img_install = b.addInstallBinFile(boot_img, "boot.img");
    boot_img_install.step.dependOn(&first_dd.step);
    boot_img_install.step.dependOn(&decompress_dd.step);
    boot_img_install.step.dependOn(&second_dd.step);
    boot_img_install.step.dependOn(&padding_dd.step);

    return boot_img_install;
}
