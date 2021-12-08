const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const print = utils.printAoc;

fn n1(a: i32, b: i32) i32 {
    const d = a - b;
    return d;
}

fn n2(a: i32, b: i32) i32 {
    const d = a - b;
    return @divExact((d * (d + 1)), 2);
}

fn minAt(arr: std.ArrayList(i32), at: i32, cost_fn: fn(a: i32, b: i32) i32) !i32 {
    var min: i32 = 0;
    for (arr.items) |item| {
        min += if (item <= at) cost_fn(at, item) else cost_fn(item, at);
    }
    return min;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    utils.g_part = .part2;
    var line_iter = try utils.LineIterator(.{.buffer_size = 10_000}).init(utils.InputType{.file = "../../inputs/day7.txt"});
    defer line_iter.deinit();

    var arr = std.ArrayList(i32).init(alloc);
    defer arr.deinit();

    const line = (try line_iter.next()).?;
    var split_iter = std.mem.tokenize(line, ",");
    var mean: i32 = 0;
    while (split_iter.next()) |num| {
        const n = try std.fmt.parseInt(i32, num, 10);
        mean += n;
        try arr.append(n);
    }

    // part 1
    std.sort.sort(i32, arr.items, {}, comptime std.sort.asc(i32));
    const medianL = arr.items[arr.items.len / 2];
    const medianR = arr.items[(arr.items.len + 1) / 2];

    if (medianL != medianR) {
        const res = std.math.min(try minAt(arr, medianL, n1), try minAt(arr, medianR, n1));
        print(.part1, "Res A: {}", .{res});
    } else {
        print(.part1, "Res B: {}", .{try minAt(arr, medianL, n1)});
    }

    // part 2
    const mean_low = @floatToInt(i32, std.math.floor(@intToFloat(f32, mean) / @intToFloat(f32,arr.items.len)));
    const mean_high = @floatToInt(i32, std.math.ceil(@intToFloat(f32, mean) / @intToFloat(f32,arr.items.len)));
    print(.part2, "Mean: {},{}\n", .{mean_low, mean_high});

    print(.part2, "Res B: {}", .{std.math.min(try minAt(arr, mean_low, n2), try minAt(arr, mean_high, n2))});
}