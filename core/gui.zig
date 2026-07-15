const fonts = @import("bitfont.zig").fonts;

pub const ConsoleVtable = struct {
    putCharAt: *const fn (*anyopaque, u8, usize, usize, u32, u32) void,
};

pub const Console = struct {
    ptr: *anyopaque,
    vtable: *ConsoleVtable,
};

pub const Gui = struct {
    id: u32,
    pitch: u32,
    width: u32,
    height: u16,
    bpp: u16,
    memory_model: u8,
    red_mask_len: u8,
    red_mask_pos: u8,
    green_mask_len: u8,
    green_mask_pos: u8,
    blue_mask_len: u8,
    blue_mask_pos: u8,
    base_ptr: usize,

    fn console(self: @This()) Console {
        return .{
            .ptr = &self,
            .vtable = &.{
                .putCharAt = printCharAt,
            },
        };
    }

    pub fn putPixel(self: @This(), x: u32, y: u32, color: u32) void {
        if (x > self.width or y > self.height)
            return;

        const bytes_per_pixel = self.bpp / 8;
        const offset = (y * self.pitch) + (x * bytes_per_pixel);
        const buffer: [*]u8 = @ptrFromInt(self.base_ptr);
        buffer[offset] = @truncate(color);
        buffer[offset + 1] = @truncate(color >> 8);
        buffer[offset + 2] = @truncate(color >> 16);
        buffer[offset + 3] = @truncate(color >> 24);
        // const pixel: *u32 = @ptrFromInt(self.base_ptr + offset);
        // pixel.* = color;
    }

    pub fn printCharAt(ptr: *anyopaque, char: u8, x: usize, y: usize, fg: u32, bg: u32) void {
        const self: *@This() = @ptrCast(ptr);

        const font_glyph = fonts[char];

        for (0..16) |cy| {
            for (0..8) |cx| {
                const pixel_x = x + cx;
                const pixel_y = y + cy;

                const shift: u3 = @truncate(7 - cx);
                const bit: u8 = (font_glyph[cy] >> shift) & 1;

                if (bit == 0) {
                    self.putPixel(pixel_x, pixel_y, bg);
                } else {
                    self.putPixel(pixel_x, pixel_y, fg);
                }
            }
        }
    }
};
