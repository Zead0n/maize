const std = @import("std");
const fonts = @import("bitfont.zig").fonts;

pub const Gui = struct {
    id: u32,
    pitch: u32,
    width: u32,
    height: u16,
    char_width: u16 = 8,
    char_height: u16 = 16,
    bpp: u16,
    memory_model: u8,
    red_mask_len: u8,
    red_mask_pos: u8,
    green_mask_len: u8,
    green_mask_pos: u8,
    blue_mask_len: u8,
    blue_mask_pos: u8,
    base_ptr: usize,

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
    }

    pub fn printCharAt(self: @This(), char: u8, x: usize, y: usize, fg: u32, bg: u32) void {
        const font_glyph = fonts[char];

        for (0..16) |cy| {
            for (0..8) |cx| {
                const pixel_x = (x * self.char_width) + cx;
                const pixel_y = (y * self.char_height) + cy;

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

    pub fn colorBackground(self: @This(), bg: u32) void {
        for (0..self.width) |x| {
            for (0..self.height) |y|
                self.putPixel(x, y, bg);
        }
    }
};
