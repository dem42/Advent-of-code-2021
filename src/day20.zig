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

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "inputs/day20.txt"});
    defer line_iter.deinit();

    const C = struct {x: isize, y: isize};
    var lookup = [_]bool{false} ** 512;
    var img_src = AutoHashMap(C, bool).init(alloc);
    defer img_src.deinit();
    var img_tar = AutoHashMap(C, bool).init(alloc);
    defer img_tar.deinit();

    const fline = (try line_iter.next()).?;
    for (fline) |ch, i| {
        lookup[i] = ch == '#';
    }
    _ = try line_iter.next();

    var ws: isize = -1;
    var hs: isize = -1;
    var we: isize = 0;
    var he: isize = 0;
    {var row: isize = 0; while (try line_iter.next()) |line| {
        for (line) |ch, col| {
            const coli = @intCast(isize, col);
            const co = C {.x = coli, .y = row};
            if (ch == '#')
                try img_src.put(co, true);
            we = max(we, coli + 1);
        }
        row += 1;
        he = max(row, he);
    }}
    we += 1;
    he += 1;

    var img = &img_src;
    var buf_img = &img_tar;
    {var step: usize = 0; while (step < 50) : (step += 1) {
        buf_img.clearRetainingCapacity();
        {var hi = hs; while(hi < he) : (hi += 1){
            {var wi = ws; while(wi < we) : (wi += 1){
                const co = C{.x = wi, .y = hi};
                var li: u9 = 0;
                {var h = co.y-1; while(h <= co.y + 1) : (h += 1){
                    {var w = co.x-1; while(w <= co.x + 1) : (w += 1){
                        li = li << 1;
                        var o_pix = if (img.contains(.{.x = w, .y = h})) @as(u9,1) else 0;
                        if (lookup[0] and step % 2 == 1) {
                            if (w <= ws or w >= we-1 or h <= hs or h >= he-1) {
                                o_pix = 1;
                            }
                        }
                        li = li | o_pix;
                    }}
                }}
                if (lookup[li]) {
                    try buf_img.put(co, true);
                }
            }}
        }}

        hs -= 1;
        ws -= 1;
        he += 1;
        we += 1;

        std.mem.swap(*AutoHashMap(C, bool), &img, &buf_img);
    }}
    part1 = img.count();

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}