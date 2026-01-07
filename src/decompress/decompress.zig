const std = @import("std");
const compressed_stage2 = @embedFile("stage2.gz");

export fn decompress_entry() noreturn {
    const stage2_addr: usize = 0xf000;
    const dest: [*]u8 = @ptrFromInt(stage2_addr);
    const dest_buf = dest[0 .. 1048 * 64];

    var compressed_reader = std.Io.Reader.fixed(compressed_stage2);
    var writer = std.Io.Writer.fixed(dest_buf);

    const decompress = std.compress.flate.Decompress.init(&compressed_reader, .gzip, &.{});
    var reader: *std.Io.Reader = @constCast(&decompress.reader);

    _ = reader.streamRemaining(&writer) catch @panic("Failed to decompress stage2");

    while (true)
        asm volatile ("hlt");

    unreachable;
}
