const std = @import("std");

pub fn createQemuCommand(b: *std.Build, lp: std.Build.LazyPath, arch: std.Target.Cpu.Arch) *std.Build.Step.Run {
    const qemu_cmd: []const u8 = switch (arch) {
        .x86 => "qemu-system-i386",
        else => std.debug.panic("No qemu support for architecture: {s}", .{@tagName(arch)}),
    };

    const cmd = b.addSystemCommand(&.{qemu_cmd});
    cmd.addArg("-hda");
    cmd.addFileArg(lp);

    return cmd;
}
