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

const PacketType = enum {
    Literal,
    Operator,
};

const Packet = struct {
    packet_type: PacketType,
    version: u3,
    type_id: u3,
    subpackets: ArrayList(Packet),
    bit_len: u64,
    lit_val: u64,

    pub fn versionSum(packet: Packet) u64 {
        var res: u64 = packet.version;
        for (packet.subpackets.items) |sp| {
            res += sp.versionSum();
        }
        return res;
    }

    pub fn eval(packet: Packet) u64 {
        var res: u64 = 0;
        switch (packet.type_id) {
            0 => {
                for (packet.subpackets.items) |sp| {
                    res += sp.eval();
                }
            },
            1 => {
                res = 1;
                for (packet.subpackets.items) |sp| {
                    res *= sp.eval();
                }
            },
            2 => {
                res = std.math.maxInt(u64);
                for (packet.subpackets.items) |sp| {
                    res = min(res, sp.eval());
                }
            },
            3 => {
                res = 0;
                for (packet.subpackets.items) |sp| {
                    res = max(res, sp.eval());
                }
            },
            4 => { res = packet.lit_val; },
            5 => {
                const left = packet.subpackets.items[0].eval();
                const right = packet.subpackets.items[1].eval();
                res = if (left > right) 1 else 0;
            },
            6 => {
                const left = packet.subpackets.items[0].eval();
                const right = packet.subpackets.items[1].eval();
                res = if (left < right) 1 else 0;
            },
            7 => {
                const left = packet.subpackets.items[0].eval();
                const right = packet.subpackets.items[1].eval();
                res = if (left == right) 1 else 0;
            }
        }
        return res;
    }

    pub fn deinit(packet: *Packet) void {
        for (packet.subpackets.items) |*sp| {
            sp.deinit();
        }
        packet.subpackets.deinit();
    }
};

fn toBits(line: []const u8, alloc: *std.mem.Allocator) !DynamicBitSet {
    var bits = try DynamicBitSet.initEmpty(line.len * 4, alloc);
    errdefer bits.deinit();
    for (line) |hex, i| {
        const hnum = try std.fmt.parseInt(u4, line[i..(i+1)], 16);
        bits.setValue(4*i, (hnum & 8) != 0);
        bits.setValue(4*i+1, (hnum & 4) != 0);
        bits.setValue(4*i+2, (hnum & 2) != 0);
        bits.setValue(4*i+3, (hnum & 1) != 0);
    }
    return bits;
}

fn read(comptime T: type, bits: DynamicBitSet, sidx: *usize) T {
    const num: usize = @typeInfo(T).Int.bits;
    var res: T = 0;
    {var i: usize = 0; while (i < num) : (i += 1) {
        if (bits.isSet(sidx.* + i))
            res = res | 1;
        if (i < num - 1) {
            res = res << 1;
        }
    }}
    sidx.* += num;
    return res;
}

fn decode(bits: DynamicBitSet, idx: usize, alloc: *std.mem.Allocator) error{OutOfMemory}!Packet {
    var res = Packet {
        .packet_type = PacketType.Literal,
        .version = 0,
        .type_id = 0,
        .subpackets = ArrayList(Packet).init(alloc),
        .bit_len = 0,
        .lit_val = 0,
    };
    errdefer res.deinit();

    var nidx = idx;
    res.version = read(u3, bits, &nidx);
    res.type_id = read(u3, bits, &nidx);

    if (res.type_id == 4) {
        res.packet_type = .Literal;
        while (true) {
            const part = read(u5, bits, &nidx);
            const mask: u5 = 16;
            res.lit_val = res.lit_val << 4;
            res.lit_val = res.lit_val | (part & ~mask);
            if ((part & mask) == 0) {
                break;
            }
        }
    } else {
        const is_variable = bits.isSet(nidx);
        nidx += 1;
        res.packet_type = .Operator;
        if (!is_variable) {
            const subs = read(u15, bits, &nidx);
            {var sread: usize = 0; while (sread < subs) {
                var spacket = try decode(bits, nidx, alloc);
                errdefer spacket.deinit();
                nidx += spacket.bit_len;
                sread += spacket.bit_len;
                try res.subpackets.append(spacket);
            }}
        } else {
            const subs = read(u11, bits, &nidx);
            {var sread: usize = 0; while (sread < subs) : (sread += 1){
                var spacket = try decode(bits, nidx, alloc);
                errdefer spacket.deinit();
                nidx += spacket.bit_len;
                try res.subpackets.append(spacket);
            }}
        }
    }
    res.bit_len = nidx - idx;
    return res;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var timer = try Timer.start();

    var part1: u64 = 0;
    var part2: u64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 5000}).init(utils.InputType{.file = "inputs/day16.txt"});
    defer line_iter.deinit();

    while (try line_iter.next()) |line| {
        var bits = try toBits(line, alloc);
        defer bits.deinit();
        var packet = try decode(bits, 0, alloc);
        defer packet.deinit();
        part1 = packet.versionSum();
        part2 = packet.eval();
        print("Part1: {}, Part2: {}\n", .{part1, part2});
    }

    print("=== Took === ({} µs) \n", .{timer.lap() / 1000});
}