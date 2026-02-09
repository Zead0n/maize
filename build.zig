const std = @import("std");
const arch_util = @import("build/arch.zig");
const bootloader_util = @import("build/bootloader.zig");
const qemu_util = @import("build/commands/qemu.zig");
const dd_util = @import("build/commands/dd.zig");

pub fn build(b: *std.Build) void {
    const arch = b.option(arch_util.Architecture, "arch", "Cpu architecture (defaults to x86)") orelse .x86;

    buildBios(b, arch);
}

fn buildBios(b: *std.Build, arch: arch_util.Architecture) void {
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

    const stage1_bin = b.addObjCopy(stage1_elf.getEmittedBin(), .{
        .basename = "stage1.bin",
        .format = .bin,
        .pad_to = 512,
    });
    stage1_bin.step.dependOn(&stage1_elf.step);

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

    const stage2_bin = b.addObjCopy(stage2_elf.getEmittedBin(), .{
        .basename = "stage2.bin",
        .format = .bin,
        .pad_to = 2048,
    });
    stage2_bin.step.dependOn(&stage2_elf.step);

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

    const bootloader = b.addInstallBinFile(
        boot_img,
        b.fmt("maize-bios-{s}.img", .{@tagName(arch)}),
    );
    bootloader.step.dependOn(&init_dd.step);
    bootloader.step.dependOn(&first_dd.step);
    bootloader.step.dependOn(&second_dd.step);

    // Bios step
    const bios_step = b.step("bios", "Build bios");
    bios_step.dependOn(&bootloader.step);

    // Bios disect step
    const bios_disect_step = b.step("bios-disect", "Disect bios stages");
    const bios_install_dir = std.Build.InstallDir{ .custom = "bios" };
    const stage1_elf_install = b.addInstallFileWithDir(stage1_elf.getEmittedBin(), bios_install_dir, "stage1.elf");
    const stage2_elf_install = b.addInstallFileWithDir(stage2_elf.getEmittedBin(), bios_install_dir, "stage2.elf");
    const stage1_bin_install = b.addInstallFileWithDir(stage1_bin.getOutput(), bios_install_dir, "stage1.bin");
    const stage2_bin_install = b.addInstallFileWithDir(stage2_bin.getOutput(), bios_install_dir, "stage2.bin");
    bios_disect_step.dependOn(&stage1_elf_install.step);
    bios_disect_step.dependOn(&stage2_elf_install.step);
    bios_disect_step.dependOn(&stage1_bin_install.step);
    bios_disect_step.dependOn(&stage2_bin_install.step);

    // Bios qemu step
    const bios_qemu_step = b.step("bios-qemu", "Build bios and run qemu");
    const bios_qemu_cmd = qemu_util.createQemuCommand(b, bootloader.source, arch.toStdArch());
    bios_qemu_cmd.step.dependOn(&bootloader.step);
    bios_qemu_step.dependOn(&bios_qemu_cmd.step);
}
