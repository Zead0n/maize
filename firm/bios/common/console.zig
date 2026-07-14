const VgaColor = enum(u4) {
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
            .blue => 0xFF000080,
            .green => 0xFF008000,
            .cyan => 0xFF008080,
            .red => 0xFF800000,
            .magenta => 0xFF800080,
            .brown => 0xFF808000,
            .light_gray => 0xFFC0C0C0,
            .dark_gray => 0xFF808080,
            .light_blue => 0xFF0000FF,
            .light_green => 0xFF00FF00,
            .light_cyan => 0xFF00FFFF,
            .light_red => 0xFFFF0000,
            .light_magenta => 0xFFFF00FF,
            .light_brown => 0xFFFFFF00,
            .white => 0xFFFFFFFF,
        };
    }
};

const RgbLevel = struct {
    r: Level,
    g: Level,
    b: Level,

    const Level = enum(u2) {
        None,
        Low,
        High,

        fn from(value: u8) @This() {
            return switch (value) {
                0...0x54 => .None,
                0x55...0xA9 => .Low,
                0xAA...0xFF => .High,
            };
        }
    };

    fn toVgaColor(value: u32) VgaColor {
        const level = RgbLevel{
            .r = Level.from(@truncate(value >> 16)),
            .g = Level.from(@truncate(value >> 8)),
            .b = Level.from(@truncate(value)),
        };

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
            .argb => |value| RgbLevel.toVgaColor(value),
        };
    }
};

const VideoInfo = struct {
    pitch: u16,
    width: u16,
    height: u16,
    bpp: u16,
    memory_model: u8,
    red_mask_len: u8,
    red_mask_pos: u8,
    green_mask_len: u8,
    green_mask_pos: u8,
    blue_mask_len: u8,
    blue_mask_pos: u8,
    addr: usize,
};

var width: u32 = 80;
var height: u32 = 25;
var background: Color = .{ .vga = .black };
var foreground: Color = .{ .vga = .light_gray };
var buffer: [*]volatile anyopaque = @ptrFromInt(0xB8000);
var cursor_pos: u32 = 0;

var vbe_enabled: bool = false;

pub fn enableVbe(framebuffer: *anyopaque, x: u32, y: u32) void {
    buffer = @ptrCast(framebuffer);
    width = x;
    height = y;

    vbe_enabled = true;
}
