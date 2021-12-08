const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const print = utils.printAoc;

pub fn solve(alloc: *std.mem.Allocator) !void {
    utils.g_part = .part2;
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day9.txt"});
    defer line_iter.deinit();

    var arr = std.ArrayList(i32).init(alloc);
    defer arr.deinit();

    var sum: usize = 0;
    while (try line_iter.next()) |line| {
        var split_iter = std.mem.tokenize(line, "|");
        while (split_iter.next()) |item| {

        }
    }

    // part 1
    print(.part1, "Res {}\n", .{});

    // part 2
    print(.part2, "Res {}\n", .{});
}