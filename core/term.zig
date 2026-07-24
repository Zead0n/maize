const std = @import("std");

pub const TermVtable = struct {
    printCharAt: *const fn (*Term, u8, usize, usize) void,
    clear: *const fn (*Term) void,
};

pub const TermConfig = struct {
    width: u16,
    height: u16,
    char_width: u16,
    char_height: u16,
    buffer: []u8,
    vtable: *const TermVtable,
    frame_buffer: usize,
};

pub const Term = struct {
    width: u16,
    height: u16,
    char_width: u16,
    char_height: u16,
    vtable: *const TermVtable,
    frame_buffer: usize,

    writer: std.Io.Writer,
    cursor_x: u16 = 0,
    cursor_y: u16 = 0,
    foreground: u32 = 0xFFAAAAAA,
    background: u32 = 0xFF000000,

    const Self = @This();

    pub fn init(config: TermConfig) Self {
        return .{
            .width = config.width,
            .height = config.height,
            .char_width = config.char_width,
            .char_height = config.char_height,
            .vtable = config.vtable,
            .frame_buffer = config.frame_buffer,
            .writer = .{
                .buffer = config.buffer,
                .vtable = &.{
                    .drain = Self.drain,
                },
            },
        };
    }

    pub fn clear(self: *@This()) void {
        self.vtable.clear(self);
    }

    fn checkAndScroll(self: *@This()) void {
        if (self.cursor_y == self.height / self.char_height) {
            self.cursor_y = 0;
        }
    }

    pub fn printChar(self: *@This(), char: u8) void {
        switch (char) {
            '\n' => {
                self.cursor_x = 0;
                self.cursor_y += 1;
                self.checkAndScroll();
            },
            else => {
                self.vtable.printCharAt(self, char, self.cursor_x, self.cursor_y);
                self.cursor_x += 1;
                if (self.cursor_x >= self.width / self.char_width) {
                    self.cursor_x = 0;
                    self.cursor_y += 1;
                    self.checkAndScroll();
                }
            },
        }
    }

    pub fn print(self: *@This(), str: []const u8) void {
        for (str) |char|
            self.writer.printAsciiChar(char, .{}) catch continue;

        self.writer.flush() catch return;
    }

    pub fn printf(self: *@This(), comptime fmt: []const u8, args: anytype) void {
        self.writer.print(fmt, args) catch return;
        self.writer.flush() catch return;
    }

    pub fn setColor(self: *@This(), fg: u32, bg: u32) void {
        self.foreground = fg;
        self.background = bg;
    }

    fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) !usize {
        const self: *Self = @fieldParentPtr("writer", w);

        std.debug.assert(data.len != 0);

        var consumed: usize = 0;
        const pattern = data[data.len - 1];
        const splat_len = pattern.len * splat;

        if (w.end != 0) {
            for (w.buffered()) |byte|
                self.printChar(byte);
            w.end = 0;
        }

        for (data[0 .. data.len - 1]) |bytes| {
            for (bytes) |byte|
                self.printChar(byte);
            consumed += bytes.len;
        }

        switch (pattern.len) {
            0 => {},
            else => {
                for (0..splat) |_| {
                    for (pattern) |byte|
                        self.printChar(byte);
                }
            },
        }
        consumed += splat_len;
        return consumed;
    }
};
