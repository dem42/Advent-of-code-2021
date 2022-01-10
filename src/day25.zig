const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const AutoHashSet = utils.AutoHashSet;
const print = std.debug.print;
const max = std.math.max;
const min = std.math.min;
const sort = std.sort.sort;
const isEql = std.mem.eql;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StaticBitSet = std.StaticBitSet;
const DynamicBitSet = std.DynamicBitSet;
const PriorityQueue = std.PriorityQueue;
const Timer = std.time.Timer;

const Cell = enum {Empty, West, South};

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "inputs/day25.txt"});
    defer line_iter.deinit();

    const M: usize = 137;
    const N: usize = 139;
    var grid: [M][N]Cell = [_][N]Cell{[_]Cell{.Empty} ** N} ** M;
    {var row: usize = 0; while (try line_iter.next()) |line| {
        for (line) |cell, col| {
            grid[row][col] = if (cell == 'v') .South else if (cell == '>') @as(Cell, .West) else .Empty;
        }
        row += 1;
    }}

    // {var i: usize = 0; while (i < M) : (i += 1) {
    //     {var j: usize = 0; while (j < N) : (j += 1) {
    //         if (grid[i][j] == .Empty) print(".", .{});
    //         if (grid[i][j] == .South) print("v", .{});
    //         if (grid[i][j] == .West) print(">", .{});
    //     }}
    //     print("\n", .{});
    // }}

    var moved = true;
    var step: usize = 0;
    while (moved) {
        step += 1;
        print("step: {}\n", .{step});
        moved = false;
        {var i: usize = 0; while (i < M) : (i += 1) {
            const zeroFree = grid[i][0] == .Empty;
            {var j: usize = 0; while (j < N) : (j += 1) {
                if (grid[i][j] != .West) continue;
                const nj = if (j + 1 < N) j + 1 else 0;
                if ((nj == 0 and zeroFree) or (nj > 0 and grid[i][nj] == .Empty)) {
                    grid[i][nj] = .West;
                    grid[i][j] = .Empty;
                    moved = true;
                    j += 1;
                }
            }}
        }}
        {var j: usize = 0; while (j < N) : (j += 1) {
            const zeroFree = grid[0][j] == .Empty;
            {var i: usize = 0; while (i < M) : (i += 1) {
                if (grid[i][j] != .South) continue;
                const ni = if (i + 1 < M) i + 1 else 0;
                if ((ni == 0 and zeroFree) or (ni > 0 and grid[ni][j] == .Empty)) {
                    grid[ni][j] = .South;
                    grid[i][j] = .Empty;
                    moved = true;
                    i += 1;
                }
            }}
        }}

        // {var i: usize = 0; while (i < M) : (i += 1) {
        //     {var j: usize = 0; while (j < N) : (j += 1) {
        //         if (grid[i][j] == .Empty) print(".", .{});
        //         if (grid[i][j] == .South) print("v", .{});
        //         if (grid[i][j] == .West) print(">", .{});
        //     }}
        //     print("\n", .{});
        // }}
    }
    part1 = step;

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}