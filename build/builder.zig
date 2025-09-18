const std = @import("std");

pub const Builder = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    pub fn buildBootloader(self: Builder, b: *std.Build) *std.Build.Step.Compile {
        const bios_dir = b.path("firm/bios");

        const stage_zero_dir = bios_dir.path(b, "stage0");

        const boot_mod = b.createModule(.{
            .target = self.target,
            .optimize = self.optimize,
        });
        boot_mod.addAssemblyFile(stage_zero_dir.path(b, "boot.s"));

        const boot_bin = b.addObject(.{
            .name = "boot.bin",
            .root_module = boot_mod,
        });
        boot_bin.setLinkerScript(stage_zero_dir.path(b, "link.ld"));

        return boot_bin;
    }
};
