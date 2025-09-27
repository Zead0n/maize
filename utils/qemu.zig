const std = @import("std");

pub fn createQemuCommand(b: *std.Build, exe: *std.Build.Step.Compile) *std.Build.Step.Run {
    const arch = exe.rootModuleTarget().cpu.arch;
    const qemu_cmd: []const u8 = switch (arch) {
        .x86 => "qemu-system-i386",
        else => std.debug.panic("No qemu support for architecture: {s}", .{@tagName(arch)}),
    };

    const cmd = b.addSystemCommand(&.{qemu_cmd});
    cmd.addArg("-hda");
    cmd.addArtifactArg(exe);

    return cmd;
}
