const maize = @import("maize");
const fonts = @import("common/bitfont.zig").fonts;
const real = @import("common/real.zig");
const vbe = @import("common/vbe.zig");
const vga = @import("common/vga.zig");
const color = @import("common/color.zig");

var buffer: [4096]u8 = undefined;
pub var term: maize.Term = maize.Term.init(.{
    .width = 80,
    .height = 25,
    .char_width = 1,
    .char_height = 1,
    .buffer = &buffer,
    .frame_buffer = 0xB8000,
    .vtable = &.{
        .printCharAt = vga.printCharAt,
        .clear = vga.clear,
    },
});

pub fn setMode(mode: u16) !*maize.Gui {
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

    term = gui;
    return &term;
}
