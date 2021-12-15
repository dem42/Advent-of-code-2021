const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const print = std.debug.print;
const max = std.math.max;
const min = std.math.min;
const sort = std.sort.sort;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StaticBitSet = std.StaticBitSet;
const DynamicBitSet = std.DynamicBitSet;
const PriorityQueue = std.PriorityQueue;

const Pair = struct {first: u8, second: u8};

fn countMostLeast(cnt_map: *AutoHashMap(Pair, u64)) u64 {
    var cnts = [_]?u64{null} ** 26;
    var en_it = cnt_map.*.iterator();
    while (en_it.next()) |kv| {
        const key = kv.key_ptr.*;
        const v1 = cnts[key.first-'A'] orelse 0;
        cnts[key.first-'A'] = v1 + kv.value_ptr.*;
        const v2 = cnts[key.second-'A'] orelse 0;
        cnts[key.second-'A'] = v2 + kv.value_ptr.*;
    }
    var most_cmn: u64 = 0;
    var least_cmn: u64 = 1 << 63;
    for (cnts) |cnt| {
        if (cnt) |val| {
            most_cmn = max(most_cmn, val);
            least_cmn = min(least_cmn, val);
        }
    }
    most_cmn = (most_cmn + 1) / 2;
    least_cmn = (least_cmn + 1) / 2;
    print("most: {}, least: {}\n", .{most_cmn, least_cmn});
    return most_cmn - least_cmn;
}

fn inc(cnt_map: *AutoHashMap(Pair, u64), key: Pair, amount: u64) void {
    cnt_map.getPtr(key).?.* += amount;
}

fn zero(cnt_map: *AutoHashMap(Pair, u64)) void {
    var val_it = cnt_map.iterator();
    while (val_it.next()) |kv| {
        kv.value_ptr.* = @as(u64, 0);
    }
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day14.txt"});
    defer line_iter.deinit();

    var str = String.init(alloc);
    defer str.deinit();
    _ = try str.writer().write((try line_iter.next()).?);
    _ = try line_iter.next();

    var lookup = AutoHashMap(Pair, [2]Pair).init(alloc);
    defer lookup.deinit();

    var cnt_map_src = AutoHashMap(Pair, u64).init(alloc);
    defer cnt_map_src.deinit();

    var cnt_map_tar = AutoHashMap(Pair, u64).init(alloc);
    defer cnt_map_tar.deinit();

    while (try line_iter.next()) |line| {
        var tok_it = std.mem.tokenize(line, " ->");
        const fp = tok_it.next().?;
        const sp = tok_it.next().?;
        const key = Pair {.first = fp[0], .second = fp[1]};
        const v1 = Pair {.first = fp[0], .second = sp[0]};
        const v2 = Pair {.first = sp[0], .second = fp[1]};
        const entry = [2]Pair{v1, v2};
        try lookup.put(key, entry);

        try cnt_map_src.put(key, 0);
        try cnt_map_tar.put(key, 0);
    }

    for (str.items) |e, i| {
        if (i == str.items.len - 1) continue;
        const key = Pair {.first = e, .second = str.items[i+1]};
        inc(&cnt_map_src, key, 1);
    }

    var from: *AutoHashMap(Pair, u64) = &cnt_map_src;
    var to: *AutoHashMap(Pair, u64) = &cnt_map_tar;
    {var step: usize = 0; while (step < 40) : (step += 1) {
        if (step == 10) {
            part1 = countMostLeast(from);
        }
        var en_it = from.*.iterator();
        while (en_it.next()) |kv| {
            const intos = lookup.get(kv.key_ptr.*).?;
            inc(to, intos[0], kv.value_ptr.*);
            inc(to, intos[1], kv.value_ptr.*);
        }
        var tmp = from;
        from = to;
        to = tmp;
        zero(to);
    }}
    part2 = countMostLeast(from);

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}