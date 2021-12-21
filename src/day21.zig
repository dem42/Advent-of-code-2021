const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const AutoHashSet = utils.AutoHashSet;
const print = std.debug.print;
const max = std.math.max;
const min = std.math.min;
const sort = std.sort.sort;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StaticBitSet = std.StaticBitSet;
const DynamicBitSet = std.DynamicBitSet;
const PriorityQueue = std.PriorityQueue;
const Timer = std.time.Timer;

fn read(line_iter: *utils.LineIterator(.{.buffer_size = 1024})) !u64 {
    const line = (try line_iter.next()).?;
    var tok = std.mem.tokenize(line, "Player starting position:");
    _ = tok.next();
    return try std.fmt.parseInt(u64, tok.next().?, 10);
}

const PINC = [_]u64{1,3,6,7,6,3,1};

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "inputs/day21.txt"});
    defer line_iter.deinit();

    const p1s_in = try read(&line_iter);
    const p2s_in = try read(&line_iter);

    var p1s = p1s_in;
    var p2s = p2s_in;
    var sc1: u64 = 0;
    var sc2: u64 = 0;
    var step: u64 = 0;
    var die: u64 = 1;
    while (sc1 < 1000 and sc2 < 1000) {
        step += 1;
        if (step % 2 == 1) {
            const inc = (p1s + die * 3 + 3) % 10;
            p1s = if (inc == 0) 10 else inc;
            sc1 += p1s;
        } else {
            const inc = (p2s + die * 3 + 3) % 10;
            p2s = if (inc == 0) 10 else inc;
            sc2 += p2s;
        }
        die += 3;
    }
    part1 = min(sc1, sc2) * (die - 1);

    const GS = struct {
        p1: u64,
        p2: u64,
        s1: u64,
        s2: u64,
    };
    var arr1 = AutoHashMap(GS, u64).init(alloc);
    defer arr1.deinit();
    var arr2 = AutoHashMap(GS, u64).init(alloc);
    defer arr2.deinit();
    var src = &arr1;
    var tar = &arr2;

    var p1wins: u64 = 0;
    var p2wins: u64 = 0;
    var p1turn = true;
    const MAX = 21;
    try arr1.put(.{.p1 = p1s_in, .p2 = p2s_in, .s1 = 0, .s2 = 0}, 1);

    while (true) {
        if (src.count() == 0) break;
        var it = src.iterator();
        while (it.next()) |kv| {
            const pos = kv.key_ptr.*;
            const univ = kv.value_ptr.*;
            if (pos.s1 >= MAX) {
                p1wins += univ;
                continue;
            }
            if (pos.s2 >= MAX) {
                p2wins += univ;
                continue;
            }
            for (PINC) |inc, i| {
                if (p1turn) {
                    var n_inc = (pos.p1 + (i + 3)) % 10;
                    if (n_inc == 0) n_inc = 10;
                    const key: GS = .{.p1 = n_inc, .p2 = pos.p2, .s1 = pos.s1 + n_inc, .s2 = pos.s2};
                    var entry = try tar.getOrPutValue(key, 0);
                    entry.value_ptr.* += univ * inc;
                } else {
                    var n_inc = (pos.p2 + (i + 3)) % 10;
                    if (n_inc == 0) n_inc = 10;
                    const key: GS = .{.p2 = n_inc, .p1 = pos.p1, .s2 = pos.s2 + n_inc, .s1 = pos.s1};
                    var entry = try tar.getOrPutValue(key, 0);
                    entry.value_ptr.* += univ * inc;
                }
            }
        }
        p1turn = !p1turn;
        std.mem.swap(*AutoHashMap(GS, u64), &src, &tar);
        tar.clearRetainingCapacity();
    }

    print("p1: {}, p2: {}\n", .{p1wins, p2wins});
    part2 = max(p1wins, p2wins);

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}