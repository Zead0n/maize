const color = @import("color.zig");
const maize = @import("maize");

const Color = packed struct(u8) {
    fg: color.VgaColor,
    bg: color.VgaColor,

    pub fn getVgaChar(self: Color, char: u8) u16 {
        return @as(u16, @as(u8, @bitCast(self))) << 8 | char;
    }
};

pub fn clear(term: *maize.Term) void {
    const fg_vga = color.VgaColor.fromRgb(term.foreground);
    const bg_vga = color.VgaColor.fromRgb(term.background);
    const colo = Color{
        .fg = fg_vga,
        .bg = bg_vga,
    };

    const frame_ptr: [*]volatile u16 = @ptrFromInt(term.frame_buffer);
    @memset(frame_ptr[0 .. term.width * term.height], colo.getVgaChar(' '));
}

pub fn printCharAt(term: *maize.Term, char: u8, x: usize, y: usize) void {
    const index = y * term.width + x;
    const fg_vga = color.VgaColor.fromRgb(term.foreground);
    const bg_vga = color.VgaColor.fromRgb(term.background);
    const colo = Color{
        .fg = fg_vga,
        .bg = bg_vga,
    };

    const frame_ptr: [*]volatile u16 = @ptrFromInt(term.frame_buffer);
    frame_ptr[index] = colo.getVgaChar(char);
}
