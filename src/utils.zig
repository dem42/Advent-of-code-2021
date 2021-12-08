const std = @import("std");

///////// String ///////////
pub const String = std.ArrayList(u8);

///////// Sorting ///////////
pub fn alphabetical(_: void, lhs: []const u8, rhs: []const u8) bool {
    var i: usize = 0;
    while (i < lhs.len and i < rhs.len) : (i += 1) {
        if (lhs[i] == rhs[i]) continue;
        return lhs[i] < rhs[i];
    }
    return lhs.len < rhs.len;
}

pub fn alphabeticalArrayLists(context: void, lhs: String, rhs: String) bool {
    return alphabetical(context, lhs.items, rhs.items);
}

///////// Bit twiddling ///////////
pub fn hbit(ch: u32) u5 {
    var highest_bit: u5 = 0;
    var chcpy = ch;
    while (chcpy > 0) {
        chcpy = chcpy >> 1;
        highest_bit += 1;
    }
    return highest_bit;
}

///////// Advent of code IO ///////////
pub const InputTypeTag = enum(u2) {
    file,
    stdin,
};
pub const InputType = union(InputTypeTag) {
    file: []const u8,
    stdin,
};

pub const LineIteratorOptions = struct {
    buffer_size: usize,
};

pub fn LineIterator(comptime options: LineIteratorOptions) type {
    return struct {
        input: std.fs.File,
        reader: std.fs.File.Reader,
        input_buffer: [options.buffer_size]u8,
        input_type_tag: InputTypeTag,

        const Self = @This();

        pub fn init(input_type: InputType) !Self {
            const instance = switch (input_type) {
                .file => |file_path| {
                    const input = try std.fs.cwd().openFile(file_path, .{ .read = true });
                    var reader = input.reader();
                    return Self {
                        .input = input,
                        .reader = reader,
                        .input_buffer = undefined,
                        .input_type_tag = .file,
                    };
                },
                .stdin => {
                    var stdin = std.io.getStdIn();
                    var reader = stdin.reader();
                    return Self {
                        .input = stdin,
                        .reader = reader,
                        .input_buffer = undefined,
                        .input_type_tag = .stdin,
                    };
                }
            };
            return instance;
        }

        pub fn deinit(self: *Self) void {
            if (self.input_type_tag == .file) {
                self.input.close();
            }
        }

        pub fn next(self: *Self) !?[] const u8 {
            while (try self.reader.readUntilDelimiterOrEof(&self.input_buffer, '\n')) |line| {
                const trimmed_line = std.mem.trimRight(u8, line, "\r");
                return trimmed_line;
            } else {
                return null;
            }
        }
    };
}

pub const Aoc = enum(u2) {
    part1,
    part2,
};
pub var g_part = Aoc.part1;

pub fn printAoc(comptime part: Aoc, comptime fmt: []const u8, args: anytype) void {
    if (part == g_part) {
        std.debug.print(fmt, args);
    }
}