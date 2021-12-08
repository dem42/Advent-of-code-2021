const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;

pub fn solve(alloc: *std.mem.Allocator) !void {
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day6.txt"});
    defer line_iter.deinit();

    var state = [_][9]u64{[_]u64{0} ** 9} ** 2;
    var t: usize = 0;
    const line = (try line_iter.next()).?;
    var split_iter = std.mem.tokenize(line, ",");
    while (split_iter.next()) |num| {
        const d = try std.fmt.parseInt(u8, num, 10);
        state[t][d] += 1;
    }

    var d_idx: usize = 0;
    while (d_idx < 256) : (d_idx += 1) {
        for (state[t]) |val, i| {
            if (i == 0) {
                state[1-t][6] += val;
                state[1-t][8] += val;
            } else {
                state[1-t][i-1] += val;
            }
        }
        for (state[t]) |*item| item.* = 0;
        t = 1 - t;
    }

    var sum: u64 = 0;
    for (state[t]) |item| {
        sum += item;
    }

    std.debug.print("Res: {}", .{sum});
}