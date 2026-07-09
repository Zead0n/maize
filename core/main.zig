const std = @import("std");

pub const BootFirm = struct {
    init: *const fn () anyerror!void,
    setResolution: *const fn () anyerror!void,
};

pub fn run(firm: BootFirm) !void {
    firm.init() catch |e| {
        std.log.err("Initialization failed - {s}", .{@errorName(e)});
        return error.Init;
    };

    firm.setResolution() catch |e| std.log.warn("Failed setting resolution - {s}", .{@errorName(e)});
}
