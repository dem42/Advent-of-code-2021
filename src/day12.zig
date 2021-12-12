const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const print = std.debug.print;
const max = std.math.max;
const min = std.math.min;
const sort = std.sort.sort;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const StaticBitSet = std.StaticBitSet;
const DynamicBitSet = std.DynamicBitSet;
const PriorityQueue = std.PriorityQueue;

const CaveGraph = StringHashMap(ArrayList([]const u8));

fn go(node: []const u8, graph: CaveGraph, seen: *StringHashMap(u8), res: *i64, can_twice: bool) error{OutOfMemory}!void {
    if (std.mem.eql(u8, node, "end")) {
        res.* += 1;
        return;
    }
    const is_small = node[0] > 'Z';
    if (is_small) {
        if (!seen.contains(node)) {
            try seen.put(node, 0);
        }
        seen.getPtr(node).?.* += 1;
    }
    const ch = graph.get(node).?;
    for (ch.items) |chi| {
        if (seen.contains(chi)) {
            const chi_small_can_twice = !std.mem.eql(u8, chi, "start");
            if (can_twice and chi_small_can_twice)
                try go(chi, graph, seen, res, false);
        } else {
            try go(chi, graph, seen, res, can_twice);
        }
    }
    if (is_small) {
        var val = seen.getPtr(node);
        if (val.?.* == 1) {
            _ = seen.remove(node);
        } else {
            val.?.* -= 1;
        }
    }
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: i64 = 0;
    var part2: i64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day12.txt"});
    defer line_iter.deinit();

    // used to own the memory of the cave strings
    var arr = ArrayList(String).init(alloc);
    defer {
        for (arr.items) |item| item.deinit();
        arr.deinit();
    }

    var graph = CaveGraph.init(alloc);
    defer {
        var val_it = graph.valueIterator();
        while (val_it.next()) |val| val.deinit();
        graph.deinit();
    }

    while (try line_iter.next()) |line| {
        var tokens = std.mem.tokenize(line, "-");
        var a = tokens.next().?;
        var b = tokens.next().?;

        var entryA = String.init(alloc);
        {
            errdefer entryA.deinit();
            _ = try entryA.writer().write(a);
            try arr.append(entryA);
        }

        var entryB = String.init(alloc);
        {
            errdefer entryB.deinit();
            _ = try entryB.writer().write(b);
            try arr.append(entryB);
        }

        if (!graph.contains(entryA.items))
            try graph.put(entryA.items, ArrayList([]const u8).init(alloc));
        if (!graph.contains(entryB.items))
            try graph.put(entryB.items, ArrayList([]const u8).init(alloc));

        try graph.getPtr(entryA.items).?.*.append(entryB.items);
        try graph.getPtr(entryB.items).?.*.append(entryA.items);
    }

    {
        var seen = StringHashMap(u8).init(alloc);
        defer seen.deinit();
        try go("start", graph, &seen, &part1, false);
    }
    {
        var seen = StringHashMap(u8).init(alloc);
        defer seen.deinit();
        try go("start", graph, &seen, &part2, true);
    }

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}