const std = @import("std");
const dd_util = @import("commands/dd.zig");
const gzip_util = @import("commands/gzip.zig");

const BuildOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

const BootStages = struct {
    first: std.Build.LazyPath,
    decompress: std.Build.LazyPath,
};

pub fn buildStageOne(b: *std.Build, options: BuildOptions) *std.Build.Step.Compile {
    const first_stage_dir = b.path("src/stage1");

    const first_stage_mod = b.createModule(.{
        .target = options.target,
        .optimize = options.optimize,
        .root_source_file = first_stage_dir.path(b, "first_stage.zig"),
    });
    first_stage_mod.addAssemblyFile(first_stage_dir.path(b, "boot.S"));

    const first_stage_bin = b.addExecutable(.{
        .name = "stage1.elf",
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
        .name = "stage2.elf",
        .root_module = second_stage_mod,
    });
    second_stage_bin.setLinkerScript(second_stage_dir.path(b, "link_stage2.ld"));

    return second_stage_bin;
}

pub fn buildDecompress(b: *std.Build, stage2_lp: std.Build.LazyPath, options: BuildOptions) *std.Build.Step.Compile {
    const stage2_gzip = gzip_util.gzipCmd(b, stage2_lp, .{ .level = .best });
    const compressed_stage2 = stage2_gzip.captureStdOut();

    // NOTE: Decompression isn't functionable, see 'src/decompress/decompress.zig' for more details
    _ = compressed_stage2;

    const decompress_dir = b.path("src/decompress");

    const decompress_mod = b.createModule(.{
        .target = options.target,
        .optimize = options.optimize,
        .root_source_file = decompress_dir.path(b, "decompress.zig"),
    });
    decompress_mod.addAssemblyFile(decompress_dir.path(b, "start.S"));
    decompress_mod.addAnonymousImport("stage2", .{
        // TODO: If and when decompression is figured out, replace 'stage2_lp' with 'compressed_stage2'
        .root_source_file = stage2_lp,
    });

    const decompress_bin = b.addExecutable(.{
        .name = "decompress.elf",
        .root_module = decompress_mod,
    });
    decompress_bin.setLinkerScript(decompress_dir.path(b, "decompress.ld"));
    decompress_bin.step.dependOn(&stage2_gzip.step);

    return decompress_bin;
}

pub fn buildBootloader(b: *std.Build, stages: BootStages) *std.Build.Step.InstallFile {
    const boot_files = b.addWriteFiles();
    const boot_img = boot_files.add("boot.img", "");

    const init_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = std.Build.LazyPath{ .cwd_relative = "/dev/zero" },
        .count = 16,
        .conv = &.{ "notrunc", "sync" },
    });

    const first_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = stages.first,
        .count = 1,
        .conv = &.{ "notrunc", "sync" },
    });

    const decompress_dd = dd_util.ddCmd(b, .{
        .of_lp = boot_img,
        .if_lp = stages.decompress,
        .seek = 1,
        .count = 15,
        .conv = &.{ "notrunc", "sync" },
    });

    const bootloader = b.addInstallBinFile(boot_img, "maize.img");
    bootloader.step.dependOn(&init_dd.step);
    bootloader.step.dependOn(&first_dd.step);
    bootloader.step.dependOn(&decompress_dd.step);

    return bootloader;
}
