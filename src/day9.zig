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

fn go(hm: [100][100]u4, marked: *[100][100]bool, rc: usize, cc: usize, r: usize, c: usize) i64 {
    if (hm[rc][cc] == 9 or marked[rc][cc]) return 0;
    marked[rc][cc] = true;
    var res: i64 = 1;
    if (cc > 0 and !marked[rc][cc-1] and hm[rc][cc-1] < 9) {
        res += go(hm, marked, rc, cc-1, r, c);
    }
    if (cc < c-1 and !marked[rc][cc+1] and hm[rc][cc+1] < 9) {
        res += go(hm, marked, rc, cc+1, r, c);
    }
    if (rc > 0 and !marked[rc-1][cc] and hm[rc-1][cc] < 9) {
        res += go(hm, marked, rc-1, cc, r, c);
    }
    if (rc < r-1 and !marked[rc+1][cc] and hm[rc+1][cc] < 9) {
        res += go(hm, marked, rc+1, cc, r, c);
    }
    return res;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: i64 = 0;
    var part2: i64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day9.txt"});
    defer line_iter.deinit();

    var arr = ArrayList(i64).init(alloc);
    defer arr.deinit();

    var r: usize = 0;
    var rc: usize = 0;
    var c: usize = 0;
    var cc: usize = 0;
    var hm: [100][100]u4 = [_][100]u4{[_]u4{0}**100}**100;
    var marked: [100][100]bool = [_][100]bool{[_]bool{false}**100}**100;

    var sum: usize = 0;
    while (try line_iter.next()) |line| {
        cc = 0;
        for (line) |height| {
            hm[rc][cc] = @intCast(u4, height - '0');
            cc += 1;
        }
        if (c == 0) {
            c = cc;
        }
        rc += 1;
    }
    r = rc;

    part2 = 1;
    rc = 0;
    while (rc < r) : (rc += 1) {
        cc = 0;
        while (cc < c) : (cc += 1) {
            const basin = go(hm, &marked, rc, cc, r, c);
            if (basin > 0)
                try arr.append(basin);

            var tn: usize = 0;
            var ncnt: usize = 0;
            if (cc > 0) {
                tn += 1;
                if (hm[rc][cc] < hm[rc][cc-1]) ncnt += 1;
            }
            if (cc < c-1) {
                tn += 1;
                if (hm[rc][cc] < hm[rc][cc+1]) ncnt += 1;
            }
            if (rc > 0) {
                tn += 1;
                if (hm[rc][cc] < hm[rc-1][cc]) ncnt += 1;
            }
            if (rc < r-1) {
                tn += 1;
                if (hm[rc][cc] < hm[rc+1][cc]) ncnt += 1;
            }
            if (tn == ncnt) part1 += hm[rc][cc] + 1;
        }
    }

    sort(i64, arr.items, {}, comptime std.sort.desc(i64));
    part2 = arr.items[0] * arr.items[1] * arr.items[2];

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}