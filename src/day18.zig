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

const SnType = enum {Regular, Snail};
const Sn = union(SnType) {
    Regular: u8,
    Snail: struct { left: *Sn, right: *Sn },

    fn clone(self: Sn, alloc: *std.mem.Allocator) error{OutOfMemory}!*Sn {
        var tempRoot = try alloc.create(Sn);
        errdefer tempRoot.deinit(alloc);

        switch (self) {
            .Regular => |val| { tempRoot.* = Sn { .Regular = val}; },
            .Snail => |*tuple| {
                tempRoot.* = Sn { .Snail = .{.left = undefined, .right = undefined}};
                tempRoot.*.Snail.left = try tuple.left.clone(alloc);
                tempRoot.*.Snail.right = try tuple.right.clone(alloc);
            }
        }
        return tempRoot;
    }

    fn magnitude(self: *Sn) u64 {
        var res: u64 = 0;
        switch (self.*) {
            .Regular => { res = self.Regular; },
            .Snail => |*tuple| {
                res = 3*tuple.left.magnitude() + 2*tuple.right.magnitude();
            }
        }
        return res;
    }

    const Shrapnel = struct {reduced: bool, l: ?u8, r: ?u8};
    fn explode(self: *Sn, depth: usize, alloc: *std.mem.Allocator) ?Shrapnel {
        switch (self.*) {
            .Regular => {},
            .Snail => |*tuple| {
                if (depth == 4) {
                    std.debug.assert(tuple.left.* == .Regular);
                    std.debug.assert(tuple.right.* == .Regular);
                    const shrap = Shrapnel{.reduced = true, .l = tuple.left.Regular, .r = tuple.right.Regular};
                    alloc.destroy(tuple.left);
                    alloc.destroy(tuple.right);
                    self.* = Sn {.Regular = 0};
                    return shrap;
                }

                var shrap = tuple.left.explode(depth + 1, alloc);
                if (shrap != null) {
                    if (shrap.?.r != null) {
                        tuple.right.add(shrap.?.r.?, .Left);
                        shrap.?.r = null;
                    }
                    return shrap;
                }

                shrap = tuple.right.explode(depth + 1, alloc);
                if (shrap != null) {
                    if (shrap.?.l != null) {
                        tuple.left.add(shrap.?.l.?, .Right);
                        shrap.?.l = null;
                    }
                }
                return shrap;
            }
        }
        return null;
    }

    const EffectType = enum {Left, Right};
    fn add(self: *Sn, amount: u8, effect: EffectType) void {
        switch (self.*) {
            .Regular => { self.Regular += amount; },
            .Snail => |*tuple| {
                switch (effect) {
                    .Left => {
                        tuple.left.add(amount, effect);
                    },
                    .Right => {
                        tuple.right.add(amount, effect);
                    }
                }
            }
        }
    }

    fn split(self: *Sn, reduced: *bool, alloc: *std.mem.Allocator) error{OutOfMemory}!*Sn {
        switch (self.*) {
            .Regular => |val| {
                if (val >= 10) {
                    self.* = Sn { .Snail = .{.left = undefined, .right = undefined}};
                    self.*.Snail.left = try alloc.create(Sn);
                    self.*.Snail.left.* = Sn {.Regular = val / 2 };
                    self.*.Snail.right = try alloc.create(Sn);
                    self.*.Snail.right.* = Sn {.Regular = val - self.*.Snail.left.Regular };
                    reduced.* = true;
                }
            },
            .Snail => |*tuple| {
                tuple.left = try split(tuple.left, reduced, alloc);
                if (!reduced.*) {
                    tuple.right = try split(tuple.right, reduced, alloc);
                }
            }
        }
        return self;
    }

    fn deinit(self: *Sn, alloc: *std.mem.Allocator) void {
        switch (self.*) {
            .Regular => {},
            .Snail => |*tuple| {
                tuple.left.deinit(alloc);
                tuple.right.deinit(alloc);
            }
        }
        alloc.destroy(self);
    }
};

fn parse(line: []const u8, i: *usize, alloc: *std.mem.Allocator) error{OutOfMemory}!*Sn {
    var tempRoot = try alloc.create(Sn);
    errdefer tempRoot.deinit(alloc);

    if (line[i.*] == '[') {
        i.* += 1;
        tempRoot.* = Sn { .Snail = .{.left = undefined, .right = undefined}};
        tempRoot.*.Snail.left = try parse(line, i, alloc);
        std.debug.assert(line[i.*] == ',');
        i.* += 1;
        tempRoot.*.Snail.right = try parse(line, i, alloc);
        std.debug.assert(line[i.*] == ']');
        i.* += 1;
    } else {
        tempRoot.* = Sn { .Regular = line[i.*] - '0' };
        i.* += 1;
    }
    return tempRoot;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var line_iter = try utils.LineIterator(.{.buffer_size = 5000}).init(utils.InputType{.file = "inputs/day18.txt"});
    defer line_iter.deinit();

    var fish = ArrayList(*Sn).init(alloc);
    defer {
        for (fish.items) |fishy| fishy.deinit(alloc);
        fish.deinit();
    }

    while (try line_iter.next()) |line| {
        var i: usize = 0;
        var operand = try parse(line, &i, alloc);
        errdefer operand.deinit(alloc);
        try fish.append(operand);
    }

    var max_mag: u64 = 0;
    var fidx: usize = 0;
    while (fidx < fish.items.len) : (fidx += 1) {
        var sidx: usize = fidx + 1;
        while (sidx < fish.items.len) : (sidx += 1) {
            var what = try fish.items[fidx].clone(alloc);
            var theFuck = try fish.items[sidx].clone(alloc);
            var root = try alloc.create(Sn);
            root.* = Sn {.Snail = .{.left = what, .right = theFuck}};
            defer root.deinit(alloc);

            var reduced = true;
            while (reduced) {
                reduced = false;
                var shrapnel = root.explode(0, alloc);
                if (shrapnel != null) reduced = true;
                if (!reduced)
                    root = try root.split(&reduced, alloc);
            }
            max_mag = max(max_mag, root.magnitude());
        }
    }
    part2 = max_mag;

    var root: *Sn = try fish.items[0].clone(alloc);
    var sidx: usize = 1;
    while (sidx < fish.items.len) : (sidx += 1) {
        var new_root = try alloc.create(Sn);
        new_root.* = Sn {.Snail = .{.left = root, .right = try fish.items[sidx].clone(alloc)}};
        var reduced = true;
        while (reduced) {
            reduced = false;
            var shrapnel = new_root.explode(0, alloc);
            if (shrapnel != null) reduced = true;
            if (!reduced)
                root = try new_root.split(&reduced, alloc);
        }
    }
    part1 = root.magnitude();
    root.deinit(alloc);

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}