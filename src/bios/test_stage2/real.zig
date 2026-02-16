pub const thunk: *Thunk = @ptrFromInt(0x8000 - 64);

extern fn realInt(int: u8) void;

pub const Thunk = packed struct {
    eax: u32 = 0,
    ebx: u32 = 0,
    ecx: u32 = 0,
    edx: u32 = 0,
    ebp: u32 = 0,
    esi: u32 = 0,
    edi: u32 = 0,
    es: u16 = 0,

    pub fn int(self: @This(), num: u8) Thunk {
        self.write();
        realInt(num);
        return thunk.*;
    }

    fn write(self: @This()) void {
        thunk.* = self;
    }
};
