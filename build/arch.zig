const std = @import("std");
const Arch = std.Target.Cpu.Arch;

pub const Stage = enum {
    First,
    Second,
};

pub const Architecture = enum {
    x86,

    pub fn toStdArch(self: Architecture) Arch {
        return switch (self) {
            .x86 => Arch.x86,
        };
    }

    pub fn getTargetQuery(self: Architecture, abi: std.Target.Abi) std.Target.Query {
        var query: std.Target.Query = .{
            .cpu_arch = self.toStdArch(),
            .os_tag = .freestanding,
            .abi = abi,
        };

        switch (self) {
            .x86 => {
                const x86_target = std.Target.x86;

                query.cpu_features_add = x86_target.featureSet(&.{ .popcnt, .soft_float });
                query.cpu_features_sub = x86_target.featureSet(&.{ .avx, .avx2, .sse, .sse2, .mmx });
            },
        }

        return query;
    }
};
