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

const AluState = struct {
    regs: [4]isize,
};

fn getOp(alu: AluState, op: Inp) isize {
    return switch (op) {
        .Reg => |reg| alu.regs[reg],
        .Num => |num| num,
    };
}

fn eval(in: u4, insts: []const Ins, init: AluState) ?AluState {
    var new = AluState {.regs = init.regs};
    for (insts) |inst| {
        switch (inst) {
            .Inp => |reg| {
                new.regs[reg] = @intCast(isize, in);
            },
            .Add => |ops| {
                var av = @intCast(isize, new.regs[ops.a]);
                av = av + getOp(new, ops.b);
                new.regs[ops.a] = av;
            },
            .Mul => |ops| {
                var av = @intCast(isize, new.regs[ops.a]);
                av = av * getOp(new, ops.b);
                new.regs[ops.a] = av;
            },
            .Div => |ops| {
                var av = @intCast(isize, new.regs[ops.a]);
                const opv = getOp(new, ops.b);
                if (opv == 0) return null;
                av = @divTrunc(av, opv);
                new.regs[ops.a] = av;
            },
            .Mod => |ops| {
                var av = @intCast(isize, new.regs[ops.a]);
                if (av < 0) return null;
                const opv = getOp(new, ops.b);
                if (opv <= 0) return null;
                av = @rem(av, opv);
                new.regs[ops.a] = av;
            },
            .Eql => |ops| {
                var av = @intCast(isize, new.regs[ops.a]);
                av = if (av == getOp(new, ops.b)) 1 else 0;
                new.regs[ops.a] = av;
            },
        }
    }
    return new;
}

const InpType = enum { Reg, Num };
const Inp = union(InpType) {
    Reg: u4,
    Num: i6,

    fn parseReg(tok: []const u8) u4 {
        return @intCast(u4, tok[0] - 'w');
    }

    fn parseOp(tok: []const u8) !Inp {
        if (tok[0] == 'w' or tok[0] == 'x' or tok[0] == 'y' or tok[0] == 'z') {
            return Inp{.Reg = parseReg(tok)};
        } else {
            const nval = try std.fmt.parseInt(i6, tok, 10);
            return Inp{.Num = nval};
        }
    }
};

const IntType = enum { Inp, Add, Mul, Div, Mod, Eql };
const Ins = union(IntType) {
    Inp: u4,
    Add: struct {a: u4, b: Inp},
    Mul: struct {a: u4, b: Inp},
    Div: struct {a: u4, b: Inp},
    Mod: struct {a: u4, b: Inp},
    Eql: struct {a: u4, b: Inp},
};

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: u64 = 0;
    var part2: u64 = 0;
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "inputs/day24.txt"});
    defer line_iter.deinit();

    var input = ArrayList(Ins).init(alloc);
    defer input.deinit();
    var inp_ids = ArrayList(usize).init(alloc);
    defer inp_ids.deinit();

    {var inp_idx: usize = 0; while (try line_iter.next()) |line| {
        var tok = std.mem.tokenize(line, " ");
        const inp_type_str = tok.next().?;
        if (isEql(u8, inp_type_str, "inp")) {
            try input.append(Ins{.Inp = Inp.parseReg(tok.next().?)});
            try inp_ids.append(inp_idx);
        } else if (isEql(u8, inp_type_str, "add")) {
            const reg = Inp.parseReg(tok.next().?);
            const operand = try Inp.parseOp(tok.next().?);
            try input.append(Ins{.Add = .{.a = reg, .b = operand}});
        } else if (isEql(u8, inp_type_str, "mul")) {
            const reg = Inp.parseReg(tok.next().?);
            const operand = try Inp.parseOp(tok.next().?);
            try input.append(Ins{.Mul = .{.a = reg, .b = operand}});
        } else if (isEql(u8, inp_type_str, "div")) {
            const reg = Inp.parseReg(tok.next().?);
            const operand = try Inp.parseOp(tok.next().?);
            try input.append(Ins{.Div = .{.a = reg, .b = operand}});
        } else if (isEql(u8, inp_type_str, "mod")) {
            const reg = Inp.parseReg(tok.next().?);
            const operand = try Inp.parseOp(tok.next().?);
            try input.append(Ins{.Mod = .{.a = reg, .b = operand}});
        } else if (isEql(u8, inp_type_str, "eql")) {
            const reg = Inp.parseReg(tok.next().?);
            const operand = try Inp.parseOp(tok.next().?);
            try input.append(Ins{.Eql = .{.a = reg, .b = operand}});
        }
        inp_idx += 1;
    }}
    try inp_ids.append(input.items.len);

    var max_map_a = AutoHashMap(AluState, u64).init(alloc);
    defer max_map_a.deinit();
    var max_map_b = AutoHashMap(AluState, u64).init(alloc);
    defer max_map_b.deinit();
    var src = &max_map_a;
    var tar = &max_map_b;

    const init = AluState {
        .regs = [_]isize{0} ** 4,
    };
    try src.put(init, 0);

    std.debug.assert(inp_ids.items.len == 15);

    var step: usize = 0;
    while (step < 14) : (step += 1) {
        const s = inp_ids.items[step];
        const e = inp_ids.items[step+1];
        var pos_in: u4 = 1;
        print("{}: state size: {}\n", .{step, src.count()});
        while (pos_in <= 9) : (pos_in += 1) {
            var it = src.iterator();
            while (it.next()) |kv| {
                const nmin = 10 * kv.value_ptr.* + pos_in;
                const start_alu = kv.key_ptr.*;
                var new_alu_op = eval(pos_in, input.items[s..e], start_alu);
                if (new_alu_op) |*new_alu| {
                    new_alu.regs[0] = 0;
                    var entry = try tar.getOrPutValue(new_alu.*, nmin);
                    if (entry.value_ptr.* > nmin) {
                        entry.value_ptr.* = nmin;
                    }
                }
            }
        }
        std.mem.swap(*AutoHashMap(AluState, u64), &src, &tar);
        tar.clearRetainingCapacity();
    }

    part2 = std.math.maxInt(u64);
    var it = src.iterator();
    while (it.next()) |kv| {
        if (kv.key_ptr.*.regs[3] == 0) {
            part2 = min(part2, kv.value_ptr.*);
        }
        //print("{}->{}\n", .{kv.key_ptr.*, kv.value_ptr.*});
    }

    print("Part1: {}, Part2: {}\n", .{part1, part2});
}