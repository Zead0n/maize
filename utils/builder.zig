const std = @import("std");

pub const Builder = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    pub fn buildBootloader(self: Builder, b: *std.Build) *std.Build.Step.Compile {
        const first_stage_dir = b.path("src/stage1");

        const first_stage_mod = b.createModule(.{
            .target = self.target,
            .optimize = self.optimize,
        });
        first_stage_mod.addAssemblyFile(first_stage_dir.path(b, "boot.S"));

        const first_stage_bin = b.addExecutable(.{
            .name = "first_stage.bin",
            .root_module = first_stage_mod,
        });
        first_stage_bin.setLinkerScript(first_stage_dir.path(b, "link_stage1.ld"));

        return first_stage_bin;
    }
};
