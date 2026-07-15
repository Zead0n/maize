const std = @import("std");

pub const Firm = struct {
    init: *const fn () anyerror!void,
};
