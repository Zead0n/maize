const std = @import("std");
const arch_util = @import("arch.zig");
const dd_util = @import("commands/dd.zig");
const gzip_util = @import("commands/gzip.zig");

pub const BiosStages = struct {
    stage_one: *std.Build.Step.Compile,
    stage_two: *std.Build.Step.Compile,
};

pub fn buildBiosStages(b: *std.Build, arch: arch_util.Architecture) BiosStages {
    const bios_dir = b.path("src/bios");

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
        .target = b.resolveTargetQuery(arch.getTargetQuery(.code16)),
        .optimize = .ReleaseSmall,
        .root_source_file = bios_dir.path(b, "stage2/main.zig"),
    });

    const stage2_elf = b.addExecutable(.{
        .name = "stage2.elf",
        .root_module = stage2_mod,
    });
    stage2_elf.setLinkerScript(bios_dir.path(b, "stage2/link_stage2.ld"));

    return .{
        .stage_one = stage1_elf,
        .stage_two = stage2_elf,
    };
}

pub fn buildBiosBootloader(b: *std.Build, name: []const u8, stages: BiosStages) *std.Build.Step.InstallFile {
    const stage1_bin = b.addObjCopy(stages.stage_one.getEmittedBin(), .{
        .basename = "stage1.bin",
        .format = .bin,
    });
    stage1_bin.step.dependOn(&stages.stage_one.step);

    const stage2_bin = b.addObjCopy(stages.stage_two.getEmittedBin(), .{
        .basename = "stage2.bin",
        .format = .bin,
    });
    stage2_bin.step.dependOn(&stages.stage_two.step);

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

// const BuildOptions = struct {
//     target: std.Build.ResolvedTarget,
//     optimize: std.builtin.OptimizeMode,
// };
//
// const BootStages = struct {
//     first: std.Build.LazyPath,
//     second: std.Build.LazyPath,
// };
//
// pub fn buildStageOne(b: *std.Build, options: BuildOptions) *std.Build.Step.Compile {
//     const first_stage_dir = b.path("src/stage1");
//
//     const utils_mod = b.createModule(.{
//         .target = options.target,
//         .optimize = options.optimize,
//         .root_source_file = b.path("utils/realmode/lib.zig"),
//     });
//
//     const first_stage_mod = b.createModule(.{
//         .target = options.target,
//         .optimize = options.optimize,
//         .root_source_file = first_stage_dir.path(b, "main.zig"),
//     });
//     first_stage_mod.addAssemblyFile(first_stage_dir.path(b, "entry.S"));
//     first_stage_mod.addImport("utils", utils_mod);
//
//     const first_stage_bin = b.addExecutable(.{
//         .name = "stage1.elf",
//         .root_module = first_stage_mod,
//     });
//     first_stage_bin.setLinkerScript(first_stage_dir.path(b, "link_stage1.ld"));
//
//     return first_stage_bin;
// }
//
// pub fn buildStageTwo(b: *std.Build, options: BuildOptions) *std.Build.Step.Compile {
//     const second_stage_dir = b.path("src/stage2");
//
//     const utils_mod = b.createModule(.{
//         .target = options.target,
//         .optimize = options.optimize,
//         .root_source_file = b.path("utils/realmode/lib.zig"),
//     });
//
//     const second_stage_mod = b.createModule(.{
//         .target = options.target,
//         .optimize = options.optimize,
//         .root_source_file = second_stage_dir.path(b, "main.zig"),
//     });
//     second_stage_mod.addImport("utils", utils_mod);
//
//     const second_stage_bin = b.addExecutable(.{
//         .name = "stage2.elf",
//         .root_module = second_stage_mod,
//     });
//     second_stage_bin.setLinkerScript(second_stage_dir.path(b, "link_stage2.ld"));
//
//     return second_stage_bin;
// }
//
// pub fn buildDecompress(b: *std.Build, stage2_lp: std.Build.LazyPath, options: BuildOptions) *std.Build.Step.Compile {
//     const stage2_gzip = gzip_util.gzipCmd(b, stage2_lp, .{ .level = .best });
//     const compressed_stage2 = stage2_gzip.captureStdOut();
//
//     // NOTE: Decompression isn't functionable, see 'src/decompress/decompress.zig' for more details
//     _ = compressed_stage2;
//
//     const decompress_dir = b.path("src/decompress");
//
//     const decompress_mod = b.createModule(.{
//         .target = options.target,
//         .optimize = options.optimize,
//         .root_source_file = decompress_dir.path(b, "decompress.zig"),
//     });
//     decompress_mod.addAssemblyFile(decompress_dir.path(b, "start.S"));
//     decompress_mod.addAnonymousImport("stage2", .{
//         // TODO: If and when decompression is figured out, replace 'stage2_lp' with 'compressed_stage2'
//         .root_source_file = stage2_lp,
//     });
//
//     const decompress_bin = b.addExecutable(.{
//         .name = "decompress.elf",
//         .root_module = decompress_mod,
//     });
//     decompress_bin.setLinkerScript(decompress_dir.path(b, "decompress.ld"));
//     decompress_bin.step.dependOn(&stage2_gzip.step);
//
//     return decompress_bin;
// }
//
// pub fn buildBootloader(b: *std.Build, stages: BootStages) *std.Build.Step.InstallFile {
//     const boot_files = b.addWriteFiles();
//     const boot_img = boot_files.add("boot.img", "");
//
//     const init_dd = dd_util.ddCmd(b, .{
//         .of_lp = boot_img,
//         .if_lp = std.Build.LazyPath{ .cwd_relative = "/dev/zero" },
//         .count = 2048,
//         .conv = &.{ "notrunc", "sync" },
//     });
//
//     const first_dd = dd_util.ddCmd(b, .{
//         .of_lp = boot_img,
//         .if_lp = stages.first,
//         .count = 1,
//         .conv = &.{ "notrunc", "sync" },
//     });
//
//     const second_dd = dd_util.ddCmd(b, .{
//         .of_lp = boot_img,
//         .if_lp = stages.second,
//         .seek = 1,
//         .count = 2047,
//         .conv = &.{ "notrunc", "sync" },
//     });
//
//     const bootloader = b.addInstallBinFile(boot_img, "maize.img");
//     bootloader.step.dependOn(&init_dd.step);
//     bootloader.step.dependOn(&first_dd.step);
//     bootloader.step.dependOn(&second_dd.step);
//
//     return bootloader;
// }
