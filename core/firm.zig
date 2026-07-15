const std = @import("std");

// pub const FirmVtable = struct {
//     init: *const fn (*anyopaque) anyerror!void,
//     setResolution: *const fn (*anyopaque) anyerror!void,
// };

pub const Firm = struct {
    init: *const fn () anyerror!void,
    // pub fn run(self: @This()) !void {
    //     self.vtable.init(self.ptr) catch |e| {
    //         std.log.err("Initialization failed - {s}", .{@errorName(e)});
    //         return error.Init;
    //     };
    //
    //     self.vtable.setResolution(self.ptr) catch |e| std.log.warn("Failed setting resolution - {s}", .{@errorName(e)});
    // }
};
