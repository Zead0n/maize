pub const VgaColor = enum(u4) {
    black = 0,
    blue = 1,
    green = 2,
    cyan = 3,
    red = 4,
    magenta = 5,
    brown = 6,
    light_gray = 7,
    dark_gray = 8,
    light_blue = 9,
    light_green = 10,
    light_cyan = 11,
    light_red = 12,
    light_magenta = 13,
    light_brown = 14,
    white = 15,

    fn toArgb(self: @This()) u32 {
        return switch (self) {
            .black => 0xFF000000,
            .blue => 0xFF0000AA,
            .green => 0xFF00AA00,
            .cyan => 0xFF00AAAA,
            .red => 0xFFAA0000,
            .magenta => 0xFFAA00AA,
            .brown => 0xFFAA5500,
            .light_gray => 0xFFAAAAAA,
            .dark_gray => 0xFF555555,
            .light_blue => 0xFF5555FF,
            .light_green => 0xFF55FF55,
            .light_cyan => 0xFF55FFFF,
            .light_red => 0xFFFF5555,
            .light_magenta => 0xFFFF55FF,
            .light_brown => 0xFFFFFF55,
            .white => 0xFFFFFFFF,
        };
    }

    pub fn fromRgb(value: u32) @This() {
        const rgb: u24 = @truncate(value);

        return switch (rgb) {
            0x000000 => .black,
            0x0000AA => .blue,
            0x00AA00 => .green,
            0x00AAAA => .cyan,
            0xAA0000 => .red,
            0xAA00AA => .magenta,
            0xAA5500 => .brown,
            0xAAAAAA => .light_gray,
            0x555555 => .dark_gray,
            0x5555FF => .light_blue,
            0x55FF55 => .light_green,
            0x55FFFF => .light_cyan,
            0xFF5555 => .light_red,
            0xFF55FF => .light_magenta,
            0xFFFF55 => .light_brown,
            0xFFFFFF => .white,
            else => .light_gray,
        };
    }
};

const Level = enum(u2) {
    None,
    Low,
    High,

    fn from(value: u8) @This() {
        return switch (value) {
            0x00 => .None,
            0x01...0x80 => .Low,
            0x81...0xFF => .High,
        };
    }
};

const RgbLevel = packed struct {
    r: Level,
    g: Level,
    b: Level,

    fn fromRgb(rgba: Rgba) @This() {
        return .{
            .r = Level.from(rgba.r),
            .g = Level.from(rgba.g),
            .b = Level.from(rgba.b),
        };
    }
};

pub const Rgba = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn fromValue(value: u32) @This() {
        return .{
            .b = @truncate(value),
            .g = @truncate(value >> 8),
            .r = @truncate(value >> 16),
            .a = @truncate(value >> 24),
        };
    }

    pub fn toVgaColor(self: @This()) VgaColor {
        const level = RgbLevel.fromRgb(self);

        return switch (level) {
            .{ .r = .None, .g = .None, .b = .None } => VgaColor.black,
            .{ .r = .Low, .g = .Low, .b = .Low } => VgaColor.dark_gray,
            .{ .r = .High, .g = .High, .b = .High } => VgaColor.white,

            .{ .r = .None, .g = .Low, .b = .High } => VgaColor.light_cyan,
            .{ .r = .None, .g = .High, .b = .Low } => VgaColor.light_cyan,
            .{ .r = .Low, .g = .None, .b = .High } => VgaColor.light_magenta,
            .{ .r = .Low, .g = .High, .b = .None } => VgaColor.light_brown,
            .{ .r = .High, .g = .None, .b = .Low } => VgaColor.light_magenta,
            .{ .r = .High, .g = .Low, .b = .None } => VgaColor.light_brown,

            .{ .r = .None, .g = .None, .b = .Low } => VgaColor.blue,
            .{ .r = .None, .g = .Low, .b = .None } => VgaColor.green,
            .{ .r = .None, .g = .Low, .b = .Low } => VgaColor.cyan,
            .{ .r = .Low, .g = .None, .b = .None } => VgaColor.red,
            .{ .r = .Low, .g = .None, .b = .Low } => VgaColor.magenta,
            .{ .r = .Low, .g = .Low, .b = .None } => VgaColor.brown,

            .{ .r = .None, .g = .None, .b = .High } => VgaColor.light_blue,
            .{ .r = .None, .g = .High, .b = .None } => VgaColor.light_green,
            .{ .r = .None, .g = .High, .b = .High } => VgaColor.light_cyan,
            .{ .r = .High, .g = .None, .b = .None } => VgaColor.light_red,
            .{ .r = .High, .g = .None, .b = .High } => VgaColor.light_magenta,
            .{ .r = .High, .g = .High, .b = .None } => VgaColor.light_brown,

            .{ .r = .Low, .g = .Low, .b = .High } => VgaColor.dark_gray,
            .{ .r = .Low, .g = .High, .b = .Low } => VgaColor.dark_gray,
            .{ .r = .High, .g = .Low, .b = .Low } => VgaColor.dark_gray,
            .{ .r = .High, .g = .High, .b = .Low } => VgaColor.light_gray,
            .{ .r = .High, .g = .Low, .b = .High } => VgaColor.light_gray,
            .{ .r = .Low, .g = .High, .b = .High } => VgaColor.light_gray,

            else => VgaColor.light_gray,
        };
    }
};

const Color = union {
    vga: VgaColor,
    argb: u32,

    pub fn toArgb(self: @This()) u32 {
        return switch (self) {
            .argb => |value| value,
            .vga => |vga_color| vga_color.toArgb(),
        };
    }

    pub fn toVga(self: @This()) VgaColor {
        return switch (self) {
            .vga => |vga| vga,
            .argb => |value| Rgba.fromValue(value).toVgaColor(),
        };
    }
};
