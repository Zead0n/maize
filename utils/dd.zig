const std = @import("std");

const DdStatus = enum {
    none,
    noxfer,
    progress,
};

const DdOptions = struct {
    bs: u32 = 512,
    conv: ?[]const []const u8 = &.{},
    count: u32 = 1,
    if_lp: std.Build.LazyPath,
    of_lp: std.Build.LazyPath,
    seek: u32 = 0,
    status: DdStatus = .none,
};

pub fn ddCmd(b: *std.Build, opts: DdOptions) *std.Build.Step.Run {
    const dd_cmd = b.addSystemCommand(&.{"dd"});
    dd_cmd.addArg(b.fmt("bs={d}", .{opts.bs}));
    dd_cmd.addArg(b.fmt("count={d}", .{opts.count}));
    dd_cmd.addArg(b.fmt("seek={d}", .{opts.seek}));
    dd_cmd.addArg(b.fmt("status={s}", .{@tagName(opts.status)}));

    if (opts.conv != null) {
        const conv_arg = std.mem.join(b.allocator, ",", opts.conv.?) catch "";
        dd_cmd.addArg(b.fmt("conv={s}", .{conv_arg}));
    }

    dd_cmd.addPrefixedFileArg("if=", opts.if_lp);
    dd_cmd.addPrefixedFileArg("of=", opts.of_lp);

    return dd_cmd;
}
