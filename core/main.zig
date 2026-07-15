const std = @import("std");
const firm = @import("firm.zig");

pub const Firm = firm.Firm;

pub fn run(os_firm: *const Firm) !void {
    os_firm.init() catch |e| {
        std.log.err("Initialization failed - {s}", .{@errorName(e)});
        return error.Init;
    };
}
