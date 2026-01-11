const std = @import("std");
const stage2_data = @embedFile("stage2");

export fn decompress() noreturn {
    var reader = std.Io.Reader.fixed(stage2_data);
    const stage2_addr: usize = 0xc000;
    var dest: [*]u8 = @ptrFromInt(stage2_addr);

    var i: usize = 0;
    while (reader.takeByte()) |byte| : (i += 1) {
        dest[i] = byte;
    } else |_| {}

    asm volatile (
        \\jmp %[stage2:P]
        :
        : [stage2] "X" (stage2_addr),
    );

    unreachable;
}

// WARN: Something's wrong with decompressing, is it a zig thing?
// Program stops when `readSliceShort` is called.
// The uncompressed version of stage2 needs to be embedded and loaded.
// Maybe this will work in the future.
//
// export fn decompress() noreturn {
//     var compressed_reader = std.Io.Reader.fixed(stage2_data);
//     const decompressed = std.compress.flate.Decompress.init(&compressed_reader, .gzip, &.{});
//     var reader: *std.Io.Reader = @constCast(&decompressed.reader);
//
//     const stage2_addr: usize = 0xc000;
//     var dest: [*]u8 = @ptrFromInt(stage2_addr);
//
//     var i: usize = 0;
//     while (reader.readSliceShort(dest[i * 512 .. (i + 1) * 512])) |read_size| : (i += 1) {
//         if (read_size < 512) break;
//     } else |_| {}
//
//     asm volatile (
//         \\jmp %[stage2:P]
//         :
//         : [stage2] "X" (stage2_addr),
//     );
//
//     while (true)
//         asm volatile ("hlt");
//
//     unreachable;
// }
