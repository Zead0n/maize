const std = @import("std");
const firm = @import("firm.zig");
const gui = @import("gui.zig");
const term = @import("term.zig");

pub const Firm = firm.Firm;
pub const Gui = gui.Gui;
pub const Term = term.Term;

pub fn run(os_firm: *const Firm) !void {
    os_firm.init() catch |e| {
        std.log.err("Initialization failed - {s}", .{@errorName(e)});
        return error.Init;
    };
}
