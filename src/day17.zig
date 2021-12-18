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
const Timer = std.time.Timer;

fn n2(a: i64) i64 {
    return @divExact((a * (a + 1)), 2);
}

fn sim(inx: i64, iny: i64, sxa: i64, exa: i64, sya: i64, eya: i64) usize {
    var i: usize = 1;
    var x_pos: i64 = 0;
    var y_pos: i64 = 0;
    var x = inx;
    var y = iny;
    while (i < 2000) : (i += 1) {
        x_pos += x;
        y_pos += y;
        if (x > 0) x -= 1;
        y -= 1;
        if (sxa <= x_pos and x_pos <= exa and sya <= y_pos and y_pos <= eya) {
            return i;
        }
        if (x_pos > exa) return 0;
        if (x == 0 and x_pos < sxa) return 0;
        if (y_pos < sya) return 0;
    }
    return 0;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var timer = try Timer.start();

    var part1: i64 = 0;
    var part2: i64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 5000}).init(utils.InputType{.file = "inputs/test/test_day17.txt"});
    defer line_iter.deinit();

    // reach max x position in x*(x+1)/2 steps (x + x-1 + x-2 + ...)
    // reach max y position if y > 0 at y*(y+1)/2 steps
    // after reaching max x we stop moving in x
    // if y > 0 then we will return to y == 0 again
    // when x is smaller than y then we will be at same height as at position
    const pref = "target area: ";
    while (try line_iter.next()) |line| {
        //target area: x=20..30, y=-10..-5
        var tokens = std.mem.tokenize(line[pref.len..], " ,x=.y");

        var sxa: i64 = try std.fmt.parseInt(i64, tokens.next().?, 10);
        var exa: i64 = try std.fmt.parseInt(i64, tokens.next().?, 10);
        var sya: i64 = try std.fmt.parseInt(i64, tokens.next().?, 10);
        var eya: i64 = try std.fmt.parseInt(i64, tokens.next().?, 10);

        part1 = n2(-sya - 1);

        var smallest_x: i64 = 1;
        var par_sum: i64 = 0;
        while (par_sum < sxa) : (smallest_x += 1) {
            par_sum += smallest_x;
        }

        {var xc: i64 = smallest_x - 1; while (xc <= exa) : (xc += 1) {
            {var yc: i64 = sya; while (yc <= (-sya - 1)) : (yc += 1) {
                const steps = sim(xc, yc, sxa, exa, sya, eya);
                if (steps != 0) {
                    part2 += 1;
                }
            }}
        }}
    }

    print("=== Took === ({} µs) \n", .{timer.lap() / 1000});
    print("Part1: {}, Part2: {}\n", .{part1, part2});
}