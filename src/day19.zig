const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const print = std.debug.print;
const max = std.math.max;
const min = std.math.min;
const sort = std.sort.sort;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;
const StaticBitSet = std.StaticBitSet;
const DynamicBitSet = std.DynamicBitSet;
const PriorityQueue = std.PriorityQueue;
const Timer = std.time.Timer;

fn HashSet(comptime T: type) type {
    return HashMap(T, void);
}

const Pt = struct {
    x: isize,
    y: isize,
    z: isize,
};

const Scanner = struct {
    pts: ArrayList(Pt),
    checked: bool,
    parent: ?usize,
    dif: ?Pt,
    rot: ?usize,
    origin: ?Pt,

    fn transformToCoordsOfOriginScanner(pt: *Pt, start_scanner: usize, scanners: []Scanner) void {
        var prev_parent = start_scanner;
        while (scanners[prev_parent].parent) |pp| {
            pt.* = d(rot(pt.*, scanners[prev_parent].rot.?), scanners[prev_parent].dif.?);
            prev_parent = pp;
        }
    }
};

fn cross(a: i8, b: i8) i8 {
    const am = std.math.absCast(a);
    const bm = std.math.absCast(b);
    const sign: i8 = if (a * b < 0) -1 else 1;
    if (am == 1 and bm == 2) return sign * 3;
    if (am == 2 and bm == 1) return sign * -3;
    if (am == 2 and bm == 3) return sign * 1;
    if (am == 3 and bm == 2) return sign * -1;
    if (am == 3 and bm == 1) return sign * 2;
    if (am == 1 and bm == 3) {
        return sign * -2;
    }
    else unreachable;
}

const RBLK = [_]i8{1,-1,2,-2,3,-3};
const MBLK = [_]i8{1,-1,2,-2};
fn rotCoord(rot_idx: usize) [3]i8 {
    const fc = rot_idx / 4;
    const sc = rot_idx % 4;
    const fcoord = RBLK[fc];
    var scoord = @intCast(i8, std.math.absCast(fcoord) + std.math.absCast(MBLK[sc]));
    scoord = if (scoord >= 4) @mod(scoord, 4) + 1 else scoord;
    scoord = if (MBLK[sc] < 0) -scoord else scoord;
    const tcoord = cross(fcoord, scoord);
    return [_]i8{fcoord, scoord, tcoord};
}

fn iRotCoord(rot_idx: usize) [3]i8 {
    const r = rotCoord(rot_idx);
    var v1: i8 = 0;
    var v2: i8 = 0;
    for (r) |rv, ri| {
        var rii: i8 = @intCast(i8, ri + 1);
        if (rv == 1 or rv == -1) {
            v1 = if (rv < 0) -rii else rii;
        }
        if (rv == 2 or rv == -2) {
            v2 = if (rv < 0)  -rii else rii;
        }
    }
    const ir = [_]i8 {v1, v2, cross(v1, v2)};
    return ir;
}

const ROT_TABLE: [24][3]i8 = comptime blk: {
    var res: [24][3]i8 = undefined;
    var rot_idx: usize = 0;
    while (rot_idx < 24) : (rot_idx += 1) {
        res[rot_idx] = rotCoord(rot_idx);
    }
    break :blk res;
};
const I_ROT_TABLE: [24][3]i8 = comptime blk: {
    var res: [24][3]i8 = undefined;
    var rot_idx: usize = 0;
    while (rot_idx < 24) : (rot_idx += 1) {
        res[rot_idx] = iRotCoord(rot_idx);
    }
    break :blk res;
};

fn rot(p1: Pt, rot_idx: usize) Pt {
    const dxx = [_]isize{p1.x, p1.y, p1.z};
    var res = Pt {.x = 0, .y = 0, .z = 0};
    set(ROT_TABLE[rot_idx][0], &res.x, dxx);
    set(ROT_TABLE[rot_idx][1], &res.y, dxx);
    set(ROT_TABLE[rot_idx][2], &res.z, dxx);
    return res;
}

fn irot(p1: Pt, rot_idx: usize) Pt {
    const dxx = [_]isize{p1.x, p1.y, p1.z};
    var res = Pt {.x = 0, .y = 0, .z = 0};
    set(I_ROT_TABLE[rot_idx][0], &res.x, dxx);
    set(I_ROT_TABLE[rot_idx][1], &res.y, dxx);
    set(I_ROT_TABLE[rot_idx][2], &res.z, dxx);
    return res;
}

fn d(p2: Pt, p1: Pt) Pt {
    return Pt{.x = p2.x - p1.x, .y = p2.y - p1.y, .z = p2.z - p1.z};
}

fn add(p2: Pt, p1: Pt) Pt {
    return Pt{.x = p2.x + p1.x, .y = p2.y + p1.y, .z = p2.z + p1.z};
}

fn set(co: i8, tar: *isize, ds: [3]isize) void {
    const sign: i8 = if (co < 0) -1 else 1;
    const aco = @intCast(usize, sign * co);
    const which = ds[aco - 1];
    tar.* = sign * which;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 5000}).init(utils.InputType{.file = "inputs/day19.txt"});
    defer line_iter.deinit();

    var scanners = ArrayList(Scanner).init(alloc);
    defer {
        for (scanners.items) |*item| {
            item.pts.deinit();
        }
        scanners.deinit();
    }

    {var scidx: usize = 0; while (try line_iter.next()) |line| {
        if (line.len == 0) {
            scidx += 1;
            continue;
        }
        if (line[0] == '-' and line[1] == '-') {
            const scan = Scanner {
                .pts = ArrayList(Pt).init(alloc),
                .checked = false,
                .parent = null,
                .dif = null,
                .rot = null,
                .origin = null,
            };
            try scanners.append(scan);
            continue;
        }
        var tokens = std.mem.tokenize(line, ",");
        try scanners.items[scidx].pts.append(Pt {
            .x = try std.fmt.parseInt(isize, tokens.next().?, 10),
            .y = try std.fmt.parseInt(isize, tokens.next().?, 10),
            .z = try std.fmt.parseInt(isize, tokens.next().?, 10),
        });
    }}

    var stack = ArrayList(usize).init(alloc);
    defer stack.deinit();

    try stack.append(0);
    var zeroP = Pt{.x = 0, .y = 0, .z = 0};
    scanners.items[0].origin = zeroP;

    var uniq = HashSet(Pt).init(alloc);
    defer uniq.deinit();
    var cnt_map = HashMap(Pt, u8).init(alloc);
    defer cnt_map.deinit();

    while (stack.items.len > 0) {
        const scidx = stack.pop();
        if (scanners.items[scidx].checked) continue;
        scanners.items[scidx].checked = true;

        sc_loop: for (scanners.items) |sc, oscidx| {
            if (sc.checked) continue;

            var rot_idx: usize = 0;
            while (rot_idx < 24) : (rot_idx += 1) {
                cnt_map.clearRetainingCapacity();
                for (sc.pts.items) |p2, p2i| {
                    const p2r = rot(p2, rot_idx);
                    for (scanners.items[scidx].pts.items) |p1, p1i| {
                        var cnt_up = try cnt_map.getOrPutValue(d(p2r, p1), 0);
                        cnt_up.value_ptr.* += 1;
                    }
                }
                var cnt_map_it = cnt_map.iterator();
                while (cnt_map_it.next()) |kv| {
                    if (kv.value_ptr.* < 12) continue;

                    const dif = kv.key_ptr.*;
                    scanners.items[oscidx].parent = scidx;
                    scanners.items[oscidx].dif = dif;
                    scanners.items[oscidx].rot = rot_idx;

                    var origin = zeroP;
                    Scanner.transformToCoordsOfOriginScanner(&origin, oscidx, scanners.items);
                    scanners.items[oscidx].origin = origin;

                    for (scanners.items[oscidx].pts.items) |pto| {
                        var trans = pto;
                        Scanner.transformToCoordsOfOriginScanner(&trans, oscidx, scanners.items);
                        try uniq.put(trans, {});
                    }

                    try stack.append(oscidx);
                    continue :sc_loop;
                }
            }
        }
    }
    for (scanners.items[0].pts.items) |pto| {
        try uniq.put(pto, {});
    }
    part1 = uniq.count();

    for (scanners.items) |sc1, i| {
        for (scanners.items) |sc2, j| {
            const d1 = std.math.absCast(sc1.origin.?.x - sc2.origin.?.x);
            const d2 = std.math.absCast(sc1.origin.?.y - sc2.origin.?.y);
            const d3 = std.math.absCast(sc1.origin.?.z - sc2.origin.?.z);
            part2 = max(part2, d1 + d2 + d3);
        }
    }
    print("Part1: {}, Part2: {}\n", .{part1, part2});
}

test "Rot" {
    const p1 = Pt {.x = -4, .y = 2, .z = -3};
    const p2 = Pt {.x = -14, .y = -2, .z = 3};
    {var ri: usize = 0; while (ri < 24) : (ri += 1) {
        {
            const p3 = irot(rot(p1, ri), ri);
            try std.testing.expect(p3.x == p1.x);
            try std.testing.expect(p3.y == p1.y);
            try std.testing.expect(p3.z == p1.z);
        }
        {
            const p3 = irot(rot(p2, ri), ri);
            try std.testing.expect(p3.x == p2.x);
            try std.testing.expect(p3.y == p2.y);
            try std.testing.expect(p3.z == p2.z);
        }
        {
            const p3 = rot(irot(p1, ri), ri);
            try std.testing.expect(p3.x == p1.x);
            try std.testing.expect(p3.y == p1.y);
            try std.testing.expect(p3.z == p1.z);
        }
        {
            const p3 = rot(irot(p2, ri), ri);
            try std.testing.expect(p3.x == p2.x);
            try std.testing.expect(p3.y == p2.y);
            try std.testing.expect(p3.z == p2.z);
        }
    }}
}

test "Rot Difs" {
    const p1 = Pt {.x = -4, .y = 2, .z = -3};
    {
        const p3 = rot(p1, 0);
        try std.testing.expect(p3.x == p1.x);
        try std.testing.expect(p3.y == p1.y);
        try std.testing.expect(p3.z == p1.z);
    }
    {
        const p3 = rot(p1, 5);
        try std.testing.expect(p3.x == -p1.x);
        try std.testing.expect(p3.y == -p1.y);
        try std.testing.expect(p3.z == p1.z);
    }
    {
        const p3 = rot(p1, 17);
        try std.testing.expect(p3.x == p1.z);
        try std.testing.expect(p3.y == -p1.x);
        try std.testing.expect(p3.z == -p1.y);
    }
}