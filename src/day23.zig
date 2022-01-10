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

const O = enum {
    A, B, C, D, Empty,

    fn cost(self: O) usize {
        return switch (self) {
            .A => 1,
            .B => 10,
            .C => 100,
            .D => 1000,
            .Empty => unreachable,
        };
    }
    fn roomIdx(self: O) usize {
        return @enumToInt(self);
    }
    fn toAmph(usize: ridx) O {
        return @intToEnum(O, @intCast(u3, ridx));
    }
};

fn roomExit(roomIdx: usize) usize {
    return (roomIdx + 1) * 2;
}

fn isNoStop(idx: usize) bool {
    return idx == 2 or idx == 4 or idx == 6 or idx == 8;
}

fn isFinal(s: S) bool {
    for (s.rooms) |room, ridx| {
        for (room) |ocu| {
            const ocui = ocu.roomIdx();
            if (ocui != ridx) return false;
        }
    }
    return true;
}

const ROOM_SIZE = 4;

const K = struct {
    hall: [11]O,
    rooms: [4][ROOM_SIZE]O,
};

const S = struct {
    hall: [11]O,
    rooms: [4][ROOM_SIZE]O,
    fixed: [4][ROOM_SIZE]bool,
    cost: u64,
    heuristic: u64,
};

fn compS(a: S, b: S) std.math.Order {
    return std.math.order(a.cost, b.cost);
}

fn compH(a: S, b: S) std.math.Order {
    return std.math.order(a.cost + a.heuristic, b.cost + b.heuristic);
}

fn dist(a: usize, b: usize) usize {
    return if (a > b) a - b else b - a;
}

fn minCostToSolve(s: S) u64 {
    var heuristic: u64 = 0;
    var need = [_][ROOM_SIZE]bool{[_]bool{false} ** ROOM_SIZE} ** 4;
    for (s.hall) |ah, hi| {
        if (ah == .Empty) continue;
        const ridx = ah.roomIdx();
        const rexit = roomExit(ridx);
        var total_cost = dist(hi, rexit) * ah.cost();
        for (need[ridx]) |*r, i| {
            if (r.* == false) {
                r.* = true;
                total_cost += (i + 1) * ah.cost();
            }
        }
        heuristic += total_cost;
    }
    for (s.rooms) |room, rid| {
        const c_rexit = roomExit(rid);
        for (room) |ocu, ocuidx| {
            if (ocu == .Empty) continue;
            const need_ridx = ocu.roomIdx();
            if (rid == need_ridx) {
                for (need[rid]) |*r, i| {
                    if (r.* == false) {
                        r.* = true;
                        break;
                    }
                }
                continue;
            }
            const n_rexit = roomExit(need_ridx);
            var total_cost = (dist(c_rexit, n_rexit) + ocuidx + 1) * ocu.cost();
            for (need[need_ridx]) |*r, i| {
                if (r.* == false) {
                    r.* = true;
                    total_cost += (i + 1) * ocu.cost();
                }
            }
            heuristic += total_cost;
        }
    }
    for (need) |need_room| {
        for (need_room) |nrval| {
            std.debug.assert(nrval);
        }
    }

    return heuristic;
}

fn getFinalFreeRoomIdx(room: [ROOM_SIZE]O) usize {
    var ffs: usize = 0;
    while (ffs < ROOM_SIZE) : (ffs += 1) {
        if (room[ffs] != .Empty) return ffs - 1;
    }
    return ROOM_SIZE - 1;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var part1: usize = 0;
    var part2: usize = 0;
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "inputs/day23.txt"});
    defer line_iter.deinit();

    var seen = AutoHashMap(K, usize).init(alloc);
    defer seen.deinit();

    var pq = PriorityQueue(S).init(alloc, compH);
    defer pq.deinit();

    var initS = S {
        .hall = [_]O{.Empty} ** 11,
        .rooms = [_][ROOM_SIZE]O{[_]O{.Empty} ** ROOM_SIZE} ** 4,
        .fixed = [_][ROOM_SIZE]bool{[_]bool{false} ** ROOM_SIZE} ** 4,
        .cost = 0,
        .heuristic = 0,
    };
    _ = (try line_iter.next()).?;
    _ = (try line_iter.next()).?;
    {var row: usize = 0; while (row < ROOM_SIZE) : (row += 1) {
        var line = (try line_iter.next()).?;
        var tokens = std.mem.tokenize(line, "# ");
        for (initS.rooms) |*room, ridx| {
            room[row] = @intToEnum(O, @intCast(u3, tokens.next().?[0] - 'A'));
        }
    }}
    print("initS: {}\n", .{initS});
    try pq.add(initS);
    const keyS = K{.hall = initS.hall, .rooms = initS.rooms};
    try seen.put(keyS, 0);
    var states_checked: usize = 0;
    while (pq.items.len > 0) {
        var top = pq.remove();
        states_checked += 1;
        const key = K{.hall = top.hall, .rooms = top.rooms};
        const seenEntry = seen.getPtr(key).?;
        if (seenEntry.* < top.cost) continue;

        if (isFinal(top)) {
            print("stop: {}\n", .{top});
            part1 = top.cost;
            break;
        }
        // hall to room
        for (top.hall) |ah, hi| {
            if (ah != .Empty) {
                const roomIdx = ah.roomIdx();
                if (top.rooms[roomIdx][0] != .Empty) continue;
                var from = min(roomExit(roomIdx), hi);
                const to = max(roomExit(roomIdx), hi);
                var cost = (to - from) * ah.cost();
                var free_path: bool = true;
                while (from <= to) : (from += 1) {
                    if (from == hi) continue;
                    if (top.hall[from] != .Empty) {
                        free_path = false;
                        break;
                    }
                }
                if (free_path) {
                    const tar_ridx = getFinalFreeRoomIdx(top.rooms[roomIdx]);
                    cost += (tar_ridx+1) * ah.cost();
                    var newS = S {.hall = top.hall, .rooms = top.rooms, .cost = top.cost + cost, .fixed = top.fixed, .heuristic = 0 };
                    newS.hall[hi] = .Empty;
                    newS.rooms[roomIdx][tar_ridx] = ah;
                    newS.fixed[roomIdx][tar_ridx] = true;
                    const newKey = K{.hall = newS.hall, .rooms = newS.rooms};

                    var entry = try seen.getOrPut(newKey);
                    if (!entry.found_existing or entry.value_ptr.* > newS.cost) {
                        newS.heuristic = minCostToSolve(newS);
                        entry.value_ptr.* = newS.cost;
                        try pq.add(newS);
                        //print("HtR: {} -> {}\n", .{top, newS});
                    }
                }
            }
        }
        // room to hall
        for (top.rooms) |room, ridx| {
            const rexit = roomExit(ridx);
            for (room) |ocu, oidx| {
                if (ocu == .Empty) continue;
                if (top.fixed[ridx][oidx]) continue;
                for (top.hall) |ah, hi| {
                    if (isNoStop(hi)) continue;
                    if (ah != .Empty) continue;
                    var from = min(rexit, hi);
                    const to = max(rexit, hi);

                    var cost = (to - from) * ocu.cost();
                    var free_path: bool = true;
                    while (from <= to) : (from += 1) {
                        if (from == hi) continue;
                        if (top.hall[from] != .Empty) {
                            free_path = false;
                            break;
                        }
                    }

                    if (free_path) {
                        cost += (oidx+1) * ocu.cost();
                        var newS = S {.hall = top.hall, .rooms = top.rooms, .cost = top.cost + cost, .fixed = top.fixed, .heuristic = 0 };
                        newS.hall[hi] = ocu;
                        newS.rooms[ridx][oidx] = .Empty;

                        const newKey = K{.hall = newS.hall, .rooms = newS.rooms};
                        var entry = try seen.getOrPut(newKey);
                        if (!entry.found_existing or entry.value_ptr.* > newS.cost) {
                            newS.heuristic = minCostToSolve(newS);
                            entry.value_ptr.* = newS.cost;
                            try pq.add(newS);
                            //print("RtH: {} -> {}\n", .{top, newS});
                        }
                    }
                }
                if (ocu != .Empty) break;
            }
        }
    }
    print("checked: {} states. cur len: {}\n", .{states_checked, pq.items.len});
    print("Part1: {}, Part2: {}\n", .{part1, part2});
}