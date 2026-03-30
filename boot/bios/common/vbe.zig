const sys = @import("sys.zig");
const real = @import("real.zig");

const VbeInfo = packed struct {
    signature: @Vector(4, u8),
    version: u16,
    oem_off: u16,
    oem_seg: u16,
    capabilities: @Vector(4, u8),
    mode_off: u16,
    mode_seg: u16,
    total_memory: u16,
    reserved: @Vector(492, u8),
};

const VbeMode = packed struct {
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
    // reserved: [206]u8,
    reserved: @Vector(206, u8),
};

const Resolution = struct {
    x: u16,
    y: u16,
};

fn fetchInfo() error{FailedInfo}!VbeInfo {
    var vbe_info: VbeInfo = undefined;
    var vbe_thunk: real.Thunk = .{
        .eax = 0x4f00,
        .edi = sys.memOffset(&vbe_info),
        .es = sys.memSegment(&vbe_info),
    };

    vbe_thunk = vbe_thunk.int(0x10);
    if (@as(u16, @truncate(vbe_thunk.eax)) != 0x004f)
        return error.FailedInfo;

    return vbe_info;
}

fn fetchBestResolution() error{FailedEdid}!Resolution {
    var edid: [128]u8 = undefined;

    var resolution_thunk = real.Thunk{
        .eax = 0x4f15,
        .ebx = 0x01,
        .edi = sys.memOffset(&edid),
        .es = sys.memSegment(&edid),
    };

    resolution_thunk = resolution_thunk.int(0x10);
    if (@as(u16, @truncate(resolution_thunk.eax)) != 0x004f)
        return error.FailedEdid;

    return .{
        .x = @as(u16, edid[0x38]) | @as(u16, edid[0x3a] & 0xf0) << 4,
        .y = @as(u16, edid[0x3b]) | @as(u16, edid[0x3d] & 0xf0) << 4,
    };
}

pub fn setResolution() void {
    var current_vbe_thunk = real.Thunk{ .eax = 0x4f03 };
    current_vbe_thunk = current_vbe_thunk.int(0x10);
    if (@as(u16, @truncate(current_vbe_thunk.eax)) != 0x004f)
        return;

    var best_mode = @as(u16, @truncate(current_vbe_thunk.ebx));
    const best_resolution = fetchBestResolution() catch Resolution{ .x = 640, .y = 480 };

    const vbe_info = fetchInfo() catch @panic("Failed to retrieve vbe info.");
    const mode_addr = sys.memFixed(vbe_info.mode_seg, vbe_info.mode_off);
    var i: usize = 0;
    while (mode_addr + i < 0xffff) : (i += 1) {
        var mode: VbeMode = undefined;

        var mode_thunk = real.Thunk{
            .eax = 0x4f01,
            .ecx = (mode_addr + i),
            .edi = sys.memOffset(&mode),
            .es = sys.memSegment(&mode),
        };

        mode_thunk = mode_thunk.int(0x10);
        if (@as(u16, @truncate(mode_thunk.eax)) != 0x004f)
            continue;

        if ((mode.attributes & 0x80) != 0x80)
            continue;

        if (mode.bits_per_pixel != 32)
            continue;

        if (mode.res_width == best_resolution.x and mode.res_height == best_resolution.y) {
            best_mode = @as(u16, @truncate(mode_addr + i));
            break;
        }
    }

    var set_vbe_thunk = real.Thunk{
        .eax = 0x4f02,
        .ebx = best_mode,
    };
    set_vbe_thunk = set_vbe_thunk.int(0x10);
    if (@as(u16, @truncate(set_vbe_thunk.eax)) != 0x004f)
        return;
}
