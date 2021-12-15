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

const N: usize = 1500;

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: i64 = 0;
    var part2: i64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/archive/day13.txt"});
    defer line_iter.deinit();

    const Fold = struct { is_x: bool, at: usize};
    var dots = [_][N]bool{[_]bool{false} ** N} ** N;
    var flines = ArrayList(Fold).init(alloc);
    defer flines.deinit();

    var width: usize = 0;
    var height: usize = 0;
    {var dots_done = false; while (try line_iter.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            dots_done = true;
            continue;
        }

        if (dots_done) {
            var tokens = std.mem.tokenize(line[11..], "=");
            const fline = .{.is_x = tokens.next().?[0] == 'x', .at = try std.fmt.parseInt(usize, tokens.next().?, 10)};
            try flines.append(fline);
        } else {
            var tokens = std.mem.tokenize(line, ",");
            const x = try std.fmt.parseInt(usize, tokens.next().?, 10);
            const y = try std.fmt.parseInt(usize, tokens.next().?, 10);
            width = max(width, x);
            height = max(height, y);
            dots[y][x] = true;
        }
    }}

    print("{}, {}\n",.{width, height});

    {var step: usize = 0; for (flines.items) |fline| {
        if (fline.is_x) {
            const width_l = fline.at;
            const width_r = width - fline.at;
            if (width_l < width_r) return error.FoldOverXIsTooSmall;
            {var r: usize = 0; while (r <= height) : (r += 1) {
                {var fidx: usize = 0; while (fidx <= width_r) : (fidx += 1) {
                    dots[r][fline.at - fidx] = dots[r][fline.at - fidx] or dots[r][fline.at + fidx];
                    dots[r][fline.at + fidx] = false;
                }}
            }}
            width = width_l - 1;
        } else {
            const height_l = fline.at;
            const height_r = height - fline.at;
            if (height_l < height_r) return error.FoldOverYIsTooSmall;
            {var c: usize = 0; while (c <= width) : (c += 1) {
                {var fidx: usize = 0; while (fidx <= height_r) : (fidx += 1) {
                    dots[fline.at - fidx][c] = dots[fline.at - fidx][c] or dots[fline.at + fidx][c];
                    dots[fline.at + fidx][c] = false;
                }}
            }}
            height = height_l - 1;
        }
        step += 1;
        if (step == 1) {
            {var r: usize = 0; while (r <= height) : (r += 1) {
                {var c: usize = 0; while (c <= width) : (c += 1) {
                    if (dots[r][c]) {
                        part1 += 1;
                    }
                }}
            }}
        }
    }}

    print("{}, {}\n",.{width, height});

    {var r: usize = 0; while (r <= height) : (r += 1) {
        {var c: usize = 0; while (c <= width) : (c += 1) {
            if (dots[r][c]) {
                part2 += 1;
                print("#",.{});
            }
            else {
                print(" ",.{});
            }
        }}
        print("\n",.{});
    }}

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}