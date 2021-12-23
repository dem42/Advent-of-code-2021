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

const Cuboid = struct {
    xs: isize,
    xe: isize,
    ys: isize,
    ye: isize,
    zs: isize,
    ze: isize,
    is_on: bool,
    val: isize,

    fn intersect(s: Cuboid, o: Cuboid) bool {
        return ((s.xs <= o.xs and o.xs < s.xe) or (o.xs <= s.xs and s.xs < o.xe))
            and ((s.ys <= o.ys and o.ys < s.ye) or (o.ys <= s.ys and s.ys < o.ye))
            and ((s.zs <= o.zs and o.zs < s.ze) or (o.zs <= s.zs and s.zs < o.ze));
    }
};

const sortFn = comptime std.sort.asc(isize);
fn genCubeIntersect(l_out: *ArrayList(Cuboid), l: Cuboid, r: Cuboid, alloc: *std.mem.Allocator) !void {
    var xss = [_]isize{l.xs, l.xe, r.xs, r.xe};
    var yss = [_]isize{l.ys, l.ye, r.ys, r.ye};
    var zss = [_]isize{l.zs, l.ze, r.zs, r.ze};

    sort(isize, xss[0..], {}, sortFn);
    sort(isize, yss[0..], {}, sortFn);
    sort(isize, zss[0..], {}, sortFn);

    var cubo = Cuboid {.xs = xss[1], .xe = xss[2], .ys = yss[1], .ye = yss[2], .zs = zss[1], .ze = zss[2], .is_on = true, .val = -l.val};
    try l_out.append(cubo);
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: i64 = 0;
    var part2: i64 = 0;
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "inputs/day22.txt"});
    defer line_iter.deinit();

    var input = ArrayList(Cuboid).init(alloc);
    defer input.deinit();
    var temp_input = ArrayList(Cuboid).init(alloc);
    defer temp_input.deinit();

    while (try line_iter.next()) |line| {
        //on x=10..12,y=10..12,z=10..12
        const is_on = line[1] == 'n';
        var tok = std.mem.tokenize(line, "onf =.,xyz");
        const xs = try std.fmt.parseInt(isize, tok.next().?, 10);
        const xe = (try std.fmt.parseInt(isize, tok.next().?, 10)) + 1;
        const ys = try std.fmt.parseInt(isize, tok.next().?, 10);
        const ye = (try std.fmt.parseInt(isize, tok.next().?, 10)) + 1;
        const zs = try std.fmt.parseInt(isize, tok.next().?, 10);
        const ze = (try std.fmt.parseInt(isize, tok.next().?, 10)) + 1;

        const ncubo = Cuboid {.xs = xs, .xe = xe, .ys = ys, .ye = ye, .zs = zs, .ze = ze, .is_on = is_on, .val = if (is_on) 1 else 0};
        for (input.items) |ocubo, idx| {
            if (ncubo.intersect(ocubo)) {
                try genCubeIntersect(&temp_input, ocubo, ncubo, alloc);
            }
        }
        if (is_on) {
            try temp_input.append(ncubo);
        }

        try input.appendSlice(temp_input.items);
        temp_input.clearRetainingCapacity();
    }

    const MIN: isize = -50;
    const MAX: isize = 51;
    for (input.items) |in| {
        if (in.is_on) {
            const xs = std.math.clamp(in.xs, MIN, MAX);
            const xe = std.math.clamp(in.xe, MIN, MAX);
            const ys = std.math.clamp(in.ys, MIN, MAX);
            const ye = std.math.clamp(in.ye, MIN, MAX);
            const zs = std.math.clamp(in.zs, MIN, MAX);
            const ze = std.math.clamp(in.ze, MIN, MAX);
            part1 += in.val * ((xe - xs) * (ye - ys) * (ze - zs));
            part2 += in.val * ((in.xe - in.xs) * (in.ye - in.ys) * (in.ze - in.zs));
        }
    }

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}