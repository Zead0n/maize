const std = @import("std");
const firm = @import("firm.zig");

pub const Firm = firm.Firm;

pub fn run(os_firm: *const Firm) !void {
    os_firm.init() catch |e| {
        std.log.err("Initialization failed - {s}", .{@errorName(e)});
        return error.Init;
    };
}

// pub const BootFirm = struct {
//     init: *const fn () anyerror!void,
//     setResolution: *const fn () anyerror!void,
//
//     pub fn run(self: @This()) !void {
//         self.init() catch |e| {
//             std.log.err("Initialization failed - {s}", .{@errorName(e)});
//             return error.Init;
//         };
//
//         self.setResolution() catch |e| std.log.warn("Failed setting resolution - {s}", .{@errorName(e)});
//     }
// };
