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

const Coord = struct {
    x: isize,
    y: isize,
};

fn getNeighbors(coord: Coord) [4]Coord {
    return [_]Coord {
        .{.x = coord.x - 1, .y = coord.y},
        .{.x = coord.x + 1, .y = coord.y},
        .{.x = coord.x, .y = coord.y - 1},
        .{.x = coord.x, .y = coord.y + 1},
    };
}

const Cell = struct {
    coord: Coord,
    total_risk: u64,
};

const CellData = struct {
    risk: u8,
    best_sofar: u64,
};

fn compCell(a: Cell, b: Cell) std.math.Order {
    return std.math.order(a.total_risk, b.total_risk);
}

fn dijkstra(width: isize, height: isize, grid: *Map2DNotOwning(CellData), alloc: *std.mem.Allocator) !u64 {
    var pq = PriorityQueue(Cell).init(alloc, compCell);
    defer pq.deinit();

    grid.*.getPtr(0,0).?.*.best_sofar = 0;
    try pq.add(.{.coord = Coord{.x = 0, .y = 0}, .total_risk = 0});

    while (true) {
        const next = pq.remove();
        var cell_data = grid.get(@intCast(usize, next.coord.y), @intCast(usize, next.coord.x)).?;
        //print("pq: {}. coord: {},{},{},{}\n", .{pq.items.len, next.coord.x, next.coord.y, next.total_risk, cell_data.best_sofar});
        if (next.total_risk > cell_data.best_sofar) continue;
        if (next.coord.x == width-1 and next.coord.y == height-1) {
            return next.total_risk;
        }

        const neighbors = getNeighbors(next.coord);
        for (neighbors) |nei| {
            if (nei.x < 0 or nei.x >= width or nei.y < 0 or nei.y >= height) continue;

            var nei_cell_data = grid.*.getPtr(@intCast(usize, nei.y), @intCast(usize, nei.x)).?;
            const nei_new_tr = next.total_risk + nei_cell_data.risk;

            if (nei_new_tr >= nei_cell_data.best_sofar) continue;
            nei_cell_data.*.best_sofar = nei_new_tr;

            try pq.add(.{.coord = nei, .total_risk = nei_new_tr});
        }
    }
    return 0;
}

const MULT: usize = 5;
pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "inputs/day15.txt"});
    defer line_iter.deinit();

    var width: usize = 0;
    var height: usize = 0;

    var data = ArrayList(CellData).init(alloc);
    defer data.deinit();
    {var row: usize = 0; while (try line_iter.next()) |line| {
        for (line) |c, col| {
            width = max(width, col + 1);
            try data.append(.{.risk = c - '0', .best_sofar = std.math.maxInt(u64)});
        }
        row += 1;
        height = max(height, row);
    }}
    var grid = Map2DNotOwning(CellData).init(data.items, width, height);

    var datax5 = ArrayList(CellData).init(alloc);
    defer datax5.deinit();
    {var row: usize = 0; while (row < MULT * height) : (row += 1) {
        const init_row = row % height;
        const block_row = row / height;
        {var col: usize = 0; while (col < MULT * width) : (col += 1) {
            const init_col = col % width;
            const block_col = col / width;
            const entry = grid.get(init_row, init_col).?;
            const ir = entry.risk;
            const nr = @intCast(u8, if (ir + block_row + block_col > 9) ir + block_row + block_col - 9 else ir + block_row + block_col);
            try datax5.append(.{.risk = nr, .best_sofar = std.math.maxInt(u64)});
        }}
    }}
    var gridx5 = Map2DNotOwning(CellData).init(datax5.items, width * MULT, height * MULT);

    part1 = try dijkstra(@intCast(isize, width), @intCast(isize, height), &grid, alloc);
    part2 = try dijkstra(@intCast(isize, width*MULT), @intCast(isize, height*MULT), &gridx5, alloc);

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}

fn Map2DNotOwning(comptime T: type) type {
    return struct {
        const Self = @This();
        data: []T,
        width: usize,
        height: usize,

        pub fn init(data: []T, width: usize, height: usize) Self {
            return .{
                .data = data,
                .width = width,
                .height = height,
            };
        }

        pub fn get(self: Self, row: usize, col: usize) ?T {
            const idx = row * self.width + col;
            if (idx < 0 or idx > self.data.len) return null;
            return self.data[idx];
        }

        pub fn getPtr(self: *Self, row: usize, col: usize) ?*T {
            const idx = row * self.width + col;
            if (idx < 0 or idx > self.data.len) return null;
            return &self.data[idx];
        }

        pub const Entry = struct {
            row: usize,
            col: usize,
            value: T,
        };

        pub const Iterator = struct {
            row: usize,
            col: usize,

            it_source: *const Self,
            index: usize,

            pub fn next(it: *Iterator) ?Entry {
                if (it.index >= it.it_source.data.len) return null;
                const res = Entry{ .row = it.row, .col = it.col, .value = it.it_source.data[index] };
                it.index += 1;
                it.col += 1;
                if (it.col == it.it_source.width) {
                    it.col = 0;
                    it.row += 1;
                }
                return res;
            }
        };
    };
}