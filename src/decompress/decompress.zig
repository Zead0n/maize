const std = @import("std");

export fn entry(compressed_stage2: [*]u8, stage2_size: usize) callconv(.c) noreturn {
    const dest: *u8 = @ptrFromInt(0xf000);

    const read_buffer: []u8 = compressed_stage2[0..stage2_size];
    var reader = std.io.Reader.fixed(read_buffer);

    _ = std.compress.flate.Decompress.init(&reader, .gzip, @ptrCast(dest));

    while (true) {}

    unreachable;
}
