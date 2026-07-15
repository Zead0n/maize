const maize = @import("maize");
const fonts = @import("common/bitfont.zig").fonts;
const real = @import("common/real.zig");
const vbe = @import("common/vbe.zig");
const vga = @import("common/vga.zig");

// var width: u32 = 80;
// var height: u32 = 25;
// var buffer: [*]volatile anyopaque = @ptrFromInt(0xB8000);
// var cursor_pos: u32 = 0;

var vbe_gui: ?maize.Gui = null;

pub fn printCharAt(char: u8, x: usize, y: usize, fg: u32, bg: u32) void {
    if (vbe_gui) |gui| {
        const font_glyph = fonts[char];

        for (0..16) |cy| {
            for (0..8) |cx| {
                const pixel_x = x + cx;
                const pixel_y = y + cy;

                const shift: u3 = @truncate(7 - cx);
                const bit: u8 = (font_glyph[cy] >> shift) & 1;

                if (bit == 0) {
                    gui.putPixel(pixel_x, pixel_y, bg);
                } else {
                    gui.putPixel(pixel_x, pixel_y, fg);
                }
            }
        }
    } else {
        // vga.printCharAt(char, fg, x, y);
    }
}

pub fn setMode(mode: u16) !void {
    try vbe.setVbeMode(mode);
    const mode_info = try vbe.getVbeModeInfo(mode);
    const gui: maize.Gui = .{
        .id = mode,
        .pitch = mode_info.pitch,
        .width = mode_info.res_width,
        .height = mode_info.res_height,
        .bpp = mode_info.bits_per_pixel,
        .memory_model = mode_info.memory_model,
        .red_mask_pos = mode_info.red_mask,
        .red_mask_len = mode_info.red_pos,
        .green_mask_pos = mode_info.green_mask,
        .green_mask_len = mode_info.green_pos,
        .blue_mask_pos = mode_info.blue_mask,
        .blue_mask_len = mode_info.blue_pos,
        .base_ptr = mode_info.framebuffer,
    };

    vbe_gui = gui;
}

// pub fn clear(_: *maize.)
