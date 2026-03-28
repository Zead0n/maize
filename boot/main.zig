const std = @import("std");

pub const BootFirm = struct {
    init: *const fn () void,
};

pub fn run(firm: BootFirm) void {
    firm.init();
    @panic("Panic from maize");
}
