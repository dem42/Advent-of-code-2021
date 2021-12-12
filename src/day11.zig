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
const PriorityQueue = std.PriorityQueue;

const Level = std.math.IntFittingRange(0, 9);

const Dumbo = struct {
    r: isize,
    c: isize,
    l: Level,
    f: bool,
};

const OFFS = [8][2]isize {
    [_]isize{0, 1},
    [_]isize{1, 1},
    [_]isize{1, 0},
    [_]isize{1, -1},
    [_]isize{0, -1},
    [_]isize{-1, -1},
    [_]isize{-1, 0},
    [_]isize{-1, 1},
};

fn updateDumbo(dumbo: *Dumbo, grid: *[10][10]Dumbo) void {
    if (dumbo.l == 9) {
        dumbo.l = 0;
        dumbo.f = true;
        for (OFFS) |off| {
            const nr = dumbo.r + off[0];
            const nc = dumbo.c + off[1];
            if ((0 <= nr) and (nr < 10) and (0 <= nc) and (nc < 10)) {
                var ndumbo = &grid[@intCast(usize, nr)][@intCast(usize, nc)];
                if (!ndumbo.*.f) {
                    updateDumbo(ndumbo, grid);
                }
            }
        }
    } else if (!dumbo.f) {
        dumbo.l += 1;
    }
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: i64 = 0;
    var part2: i64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day11.txt"});
    defer line_iter.deinit();

    var grid: [10][10]Dumbo = undefined;

    {var row: usize = 0; while (try line_iter.next()) |line| {
        for (line) |li, col| {
            grid[row][col] = Dumbo {
                .r = @intCast(isize, row),
                .c = @intCast(isize, col),
                .l = @intCast(Level, li - '0'),
                .f = false,
            };
        }
        row += 1;
    }}

    {var step: usize = 0; while (step < 400) : (step += 1) {
        for (grid) |*dumbos| {
            for (dumbos) |*dumbo| {
                updateDumbo(dumbo, &grid);
            }
        }

        var flashed: i64 = 0;
        for (grid) |*dumbos| {
            for (dumbos) |*dumbo| {
                if (dumbo.f) {
                    flashed += 1;
                    dumbo.f = false;
                }
            }
        }
        if (flashed == 100 and part2 == 0) {
            part2 = @intCast(i64, step) + 1;
            break;
        }
        if (step < 100) {
            part1 += flashed;
        }
    }}

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}