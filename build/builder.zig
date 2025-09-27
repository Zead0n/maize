const std = @import("std");

pub const Builder = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    pub fn buildBootloader(self: Builder, b: *std.Build) *std.Build.Step.Compile {
        const first_stage_dir = b.path("src/stage1");

        const boot_mod = b.createModule(.{
            .target = self.target,
            .optimize = self.optimize,
        });
        boot_mod.addAssemblyFile(first_stage_dir.path(b, "boot.S"));

        const boot_bin = b.addExecutable(.{
            .name = "boot.bin",
            .root_module = boot_mod,
        });
        boot_bin.setLinkerScript(first_stage_dir.path(b, "link.ld"));

        return boot_bin;
    }
};
