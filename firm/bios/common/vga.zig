const std = @import("std");
const color = @import("color.zig");

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

var g_row: usize = 0;
var g_column: usize = 0;
var g_color: Color = .init(.light_gray, .black);
var g_buffer = @as([*]volatile u16, @ptrFromInt(0xb8000));

const Color = packed struct(u8) {
    fg: color.VgaColor,
    bg: color.VgaColor,

    pub fn init(fg: color.VgaColor, bg: color.VgaColor) Color {
        return .{ .fg = fg, .bg = bg };
    }

    pub fn getVgaChar(self: Color, char: u8) u16 {
        return @as(u16, @as(u8, @bitCast(self))) << 8 | char;
    }
};

pub fn setColor(fg: color.VgaColor, bg: color.VgaColor) void {
    g_color = Color.init(fg, bg);
}

pub fn clear() void {
    @memset(g_buffer[0..VGA_SIZE], Color.getVgaChar(g_color, ' '));
}

pub fn printCharAt(char: u8, x: usize, y: usize, fg: color.VgaColor, bg: color.VgaColor) void {
    const index = y * VGA_WIDTH + x;
    const colo = Color{
        .fg = fg,
        .bg = bg,
    };
    g_buffer[index] = colo.getVgaChar(char);
}

fn checkAndScroll() void {
    if (g_row == VGA_HEIGHT) {
        g_row = 0;
    }
}

pub fn printChar(char: u8) void {
    switch (char) {
        '\n' => {
            g_column = 0;
            g_row += 1;
            checkAndScroll();
        },
        else => {
            printCharAt(char, g_column, g_row, g_color.fg, g_color.fg);
            g_column += 1;
            if (g_column == VGA_WIDTH) {
                g_column = 0;
                g_row += 1;
                checkAndScroll();
            }
        },
    }
}

fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) !usize {
    std.debug.assert(data.len != 0);

    var consumed: usize = 0;
    const pattern = data[data.len - 1];
    const splat_len = pattern.len * splat;

    if (w.end != 0) {
        printString(w.buffered());
        w.end = 0;
    }

    for (data[0 .. data.len - 1]) |bytes| {
        printString(bytes);
        consumed += bytes.len;
    }

    switch (pattern.len) {
        0 => {},
        else => {
            for (0..splat) |_| {
                printString(pattern);
            }
        },
    }
    consumed += splat_len;
    return consumed;
}

pub fn writer(buffer: []u8) std.Io.Writer {
    return .{
        .buffer = buffer,
        .end = 0,
        .vtable = &.{
            .drain = drain,
        },
    };
}

pub fn printString(str: []const u8) void {
    for (str) |char|
        printChar(char);
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    var w = writer(&.{});
    w.print(fmt, args) catch return;
}
