const std = @import("std");
const Arch = std.Target.Cpu.Arch;

pub const Architecture = enum {
    x86,

    pub fn toStdArch(self: Architecture) Arch {
        return switch (self) {
            .x86 => Arch.x86,
        };
    }

    pub fn getTargetQuery(self: Architecture) std.Target.Query {
        var query: std.Target.Query = .{
            .cpu_arch = self.toStdArch(),
            .os_tag = .freestanding,
            .abi = .none,
        };

        switch (self) {
            .x86 => {
                const Target = std.Target.x86;

                query.cpu_features_add = Target.featureSet(&.{ .popcnt, .soft_float });
                query.cpu_features_sub = Target.featureSet(&.{ .avx, .avx2, .sse, .sse2, .mmx });
            },
        }

        return query;
    }
};
