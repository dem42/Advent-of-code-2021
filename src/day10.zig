const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const print = std.debug.print;
const max = std.math.max;
const sort = std.sort.sort;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StaticBitSet = std.StaticBitSet;
const DynamicBitSet = std.DynamicBitSet;

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: i64 = 0;
    var part2: i64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day10.txt"});
    defer line_iter.deinit();

    var scores = ArrayList(i64).init(alloc);
    defer scores.deinit();

    var arr = ArrayList(u8).init(alloc);
    defer arr.deinit();

    const ParenScore = struct { match: u8, score: i64 };
    var lookup = AutoHashMap(u8, ParenScore).init(alloc);
    defer lookup.deinit();
    try lookup.put('(', .{.match = ')', .score = 1});
    try lookup.put('[', .{.match = ']', .score = 2});
    try lookup.put('{', .{.match = '}', .score = 3});
    try lookup.put('<', .{.match = '>', .score = 4});
    try lookup.put(')', .{.match = '(', .score = 3});
    try lookup.put(']', .{.match = '[', .score = 57});
    try lookup.put('}', .{.match = '{', .score = 1197});
    try lookup.put('>', .{.match = '<', .score = 25137});

    while (try line_iter.next()) |line| {
        var is_corrupt = line_loop: for (line) |c, _| {
            switch (c) {
                '(', '{', '<', '[' => try arr.append(c),
                ')', '}', '>', ']' => {
                    const paren = lookup.get(c) orelse unreachable;
                    if (arr.items.len == 0 or arr.items[arr.items.len-1] != paren.match) {
                        part1 += paren.score;
                        break :line_loop true;
                    } else {
                        _ = arr.pop();
                    }
                },
                else => unreachable,
            }
        } else false;

        if (!is_corrupt) {
            var tot_score: i64 = 0;
            while (arr.items.len > 0) {
                switch (arr.pop()) {
                    '(', '{', '<', '[' => |sym| {
                        const paren = lookup.get(sym) orelse unreachable;
                        tot_score = tot_score * 5 + paren.score;
                    },
                    else => unreachable,
                }
            }
            try scores.append(tot_score);
        }

        arr.clearAndFree();
    }

    sort(i64, scores.items, {}, comptime std.sort.asc(i64));
    part2 = scores.items[scores.items.len / 2];

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}