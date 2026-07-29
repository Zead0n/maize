const core = @import("core");
const fonts = @import("common/bitfont.zig").fonts;
const real = @import("common/real.zig");
const vbe = @import("common/vbe.zig");
const color = @import("common/color.zig");

var buffer: [4096]u8 = undefined;
pub var term: core.Term = core.Term.init(.{
    .width = 80,
    .height = 25,
    .char_width = 1,
    .char_height = 1,
    .buffer = &buffer,
    .frame_buffer = 0xB8000,
    .vtable = &.{
        .printCharAt = vgaPrintCharAt,
        .clear = vgaClear,
    },
});

pub fn setMode(mode: u16) !*core.Gui {
    try vbe.setVbeMode(mode);
    const mode_info = try vbe.getVbeModeInfo(mode);
    const gui: core.Gui = .{
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

const Color = packed struct(u8) {
    fg: color.VgaColor,
    bg: color.VgaColor,

    pub fn getVgaChar(self: Color, char: u8) u16 {
        return @as(u16, @as(u8, @bitCast(self))) << 8 | char;
    }
};

pub fn vgaClear(vgaTerm: *core.Term) void {
    const fg_vga = color.VgaColor.fromRgb(vgaTerm.foreground);
    const bg_vga = color.VgaColor.fromRgb(vgaTerm.background);
    const colo = Color{
        .fg = fg_vga,
        .bg = bg_vga,
    };

    const frame_ptr: [*]volatile u16 = @ptrFromInt(vgaTerm.frame_buffer);
    @memset(frame_ptr[0 .. vgaTerm.width * vgaTerm.height], colo.getVgaChar(' '));
}

pub fn vgaPrintCharAt(vgaTerm: *core.Term, char: u8, x: usize, y: usize) void {
    const index = y * vgaTerm.width + x;
    const fg_vga = color.VgaColor.fromRgb(vgaTerm.foreground);
    const bg_vga = color.VgaColor.fromRgb(vgaTerm.background);
    const colo = Color{
        .fg = fg_vga,
        .bg = bg_vga,
    };

    const frame_ptr: [*]volatile u16 = @ptrFromInt(vgaTerm.frame_buffer);
    frame_ptr[index] = colo.getVgaChar(char);
}
