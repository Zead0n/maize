const std = @import("std");

pub fn fileContent(b: *std.Build, sub_path: []const u8) []u8 {
    const file = b.path("").getPath3(b, null).openFile(sub_path, .{}) catch
        std.debug.panic("Failed to get file: {s}", .{sub_path});
    const content = file.readToEndAlloc(b.allocator, std.math.maxInt(usize)) catch
        std.debug.panic("Failed to read file content: {s}", .{sub_path});

    return content;
}
