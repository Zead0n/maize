const std = @import("std");
const data = @embedFile("stage2");

export fn decompress() noreturn {
    var reader = std.Io.Reader.fixed(data);
    const stage2_addr: usize = 0xc000;
    var dest: [*]u8 = @ptrFromInt(stage2_addr);

    var i: usize = 0;
    while (reader.takeByte()) |byte| : (i += 1) {
        dest[i] = byte;
    } else |_| {}

    asm volatile (
        \\jmp 0xc000
    );

    while (true)
        asm volatile ("hlt");

    unreachable;
}

// WARN: Somethings wrong with the decompress functionallity with zig
// so the uncompressed version of stage2 needs to be embedded and loaded.
// Maybe this will work in the future.
//
// export fn broken_decompress() linksection(".text") noreturn {
//     var decom_buf: [std.compress.flate.max_window_len]u8 = undefined;
//     var compressed_reader = std.Io.Reader.fixed(data);
//
//     const decompressed = std.compress.flate.Decompress.init(&compressed_reader, .gzip, &decom_buf);
//     var reader: *std.Io.Reader = @constCast(&decompressed.reader);
//
//     const stage2_addr: usize = 0xc000;
//     var dest: [*]u8 = @ptrFromInt(stage2_addr);
//
//     var i: usize = 0;
//     while (reader.takeByte()) |byte| : (i += 1) {
//         dest[i] = byte;
//     } else |_| {}
//
//     asm volatile (
//         \\jmp 0xc000
//     );
//
//     while (true)
//         asm volatile ("hlt");
//
//     unreachable;
// }
