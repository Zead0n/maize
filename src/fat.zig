const std = @import("std");

const FatType = enum {
    Fat12,
    Fat16,
    Fat32,
};

const Fat16Extention = packed struct {
    drive_num: u8,
    reserved: u8,
    signature: u8,
    volume_id: u32,
};

const Fat32Extention = packed struct {
    sectors_per_fat_32: u32,
    extended_flags: u16,
    version: u16,
    root_cluster: u32,
    info: u16,
    backup_sector: u16,
    reserved0: @Vector(12, u8),
    drive_num: u8,
    reserved1: u8,
    signature: u8,
    volume_id: u32,
};

const FatExtention = union {
    Fat16: *Fat16Extention,
    Fat32: *Fat32Extention,
};

pub const BiosParameterBlock = packed struct {
    bytes_per_sector: u16,
    sectors_per_cluster: u8,
    reserved_sectors: u16,
    fats: u8,
    root_entries: u16,
    total_sectors_16: u16,
    media_descriptor: u8,
    sectors_per_fat_16: u16,
    sectors_per_track: u16,
    heads: u16,
    hidden_sectors: u32,
    total_sectors_32: u32,
    extended: @Vector(54, u8),

    pub fn fatType(self: @This()) FatType {
        const total_sectors: u32 = if (self.total_sectors_16 == 0) self.total_sectors_32 orelse self.total_sectors_16;
        const root_sectors = ((self.root_entries * 32) + (self.bytes_per_sector - 1)) / self.bytes_per_sector;
        const data_sectors = total_sectors - (self.reserved_sectors + (self.fats * self.sectors_per_fat_16) + root_sectors);
        const total_clusters = data_sectors / self.sectors_per_cluster;

        return if (total_clusters < 4085) .Fat12 else if (total_clusters < 65525) .Fat16 else .Fat32;
    }

    pub fn extention(self: @This()) FatExtention {
        return switch (self.fatType()) {
            .Fat12, .Fat16 => FatExtention{ .Fat16 = @ptrCast(&self.extended) },
            .Fat32 => FatExtention{ .Fat32 = @ptrCast(&self.extended) },
        };
    }
};

pub const BootSector = packed struct {
    boot_jmp: @Vector(3, u8),
    oem: @Vector(8, u8),
    bpb: BiosParameterBlock,
    boot_code: @Vector(420, u8),
    boot_magic: @Vector(2, u8),
};

pub const FatFilesystem = struct {
    fat_type: FatType,
    bpb: *BiosParameterBlock,

    pub fn init(data: []u8) @This() {
        const boot_sector: *BootSector = @ptrCast(data);
        const boot_bpb = boot_sector.bpb;
        return .{
            .fat_type = boot_bpb.fatType(),
            .bpb = *boot_bpb,
        };
    }
};
