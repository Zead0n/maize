const std = @import("std");

const GzipOptions = struct {
    recursive: bool = false,
    level: enum { fast, best } = .fast,
};

pub fn gzipCmd(b: *std.Build, lp: std.Build.LazyPath, options: GzipOptions) *std.Build.Step.Run {
    const gzip_cmd = b.addSystemCommand(&.{"gzip"});

    if (options.recursive) gzip_cmd.addArg("--recursive");
    gzip_cmd.addArg("--keep");
    gzip_cmd.addArg("--synchronous");
    gzip_cmd.addArg("--stdout");
    gzip_cmd.addArg("--no-name");
    gzip_cmd.addArg(b.fmt("--{s}", .{@tagName(options.level)}));
    gzip_cmd.addFileArg(lp);

    return gzip_cmd;
}
