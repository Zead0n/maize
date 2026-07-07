const std = @import("std");

pub const BootFirm = struct {
    init: *const fn () anyerror!void,
};

pub fn run(firm: BootFirm) void {
    firm.init() catch @panic("Initialization failed.");
    @panic("Panic from maize");
}
