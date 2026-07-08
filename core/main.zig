const std = @import("std");

pub const BootFirm = struct {
    init: *const fn () anyerror!void,
    setResolution: *const fn () anyerror!void,
};

pub fn run(firm: BootFirm) void {
    firm.init() catch @panic("Initialization failed.");
    firm.setResolution() catch @panic("Failed to set resolution.");
}
