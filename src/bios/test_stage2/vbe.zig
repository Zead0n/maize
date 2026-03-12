const cpu = @import("cpu.zig");
const real = @import("real.zig");

const VideoError = error{FailedInfo};

pub const VbeInfoBlock = packed struct {
    signature: [4]u8,
    version: u16,
    oem_ptr: [2]u16,
    capabilities: [4]u8,
    mode_ptr: [2]u16,
    total_memory: u16,
    reserved: [492]u8,
};

pub const VbeModeInfo = packed struct {
    attributes: u16,
    window_a: u8,
    window_b: u8,
    granularity: u16,
    window_size: u16,
    segment_a: u16,
    segment_b: u16,
    window_func_ptr: u32, // NOTE: Perhaps make this a *anyopaque ?
    pitch: u16,
    res_width: u16,
    res_height: u16,
    char_width: u8,
    char_height: u8,
    planes: u8,
    bits_per_pixel: u8,
    banks: u8,
    memory_model: u8,
    bank_size: u8,
    image_pages: u8,
    unused: u8,
    red_mask: u8,
    red_pos: u8,
    green_mask: u8,
    green_pos: u8,
    blue_mask: u8,
    blue_pos: u8,
    reserved_mask: u8,
    reserved_pos: u8,
    direct_color_attributes: u8,
    framebuffer: u32,
    off_screen_mem_off: u32,
    off_screen_mem_size: u32,
    reserved: [206]u8,
};

fn findMode() VideoError!void {
    var vbe_info: VbeInfoBlock = undefined;
    var vbe_thunk: real.Thunk = .{
        .eax = 0x4f00,
        .edi = cpu.memOffset(&vbe_info),
        .es = cpu.memSegment(&vbe_info),
    };

    vbe_thunk = vbe_thunk.int(0x10);
    if (@as(u16, @truncate(vbe_thunk.eax)) != 0x004f)
        return error.FailedInfo;
}
