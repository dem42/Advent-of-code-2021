const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;

const GoType = enum {
    high,
    low,
};

fn go(nums: std.ArrayList(String), go_type: GoType) !u32 {
    var s: usize = 0;
    var e: usize = nums.items.len - 1;
    var high_bit: usize = 0;

    // std.log.info("input", .{});
    // for (nums.items) |num, i| std.log.info("{}: {s}",.{i,num.items});

    while (s != e) {
        var idx = s;
        var z_cnt: usize = 0;
        const total: usize = (e - s + 1);
        while (idx <= e) : (idx += 1) {
            if (nums.items[idx].items[high_bit] == '0') {
                z_cnt += 1;
            } else {
                break;
            }
        }
        //std.log.info("idx: {},{},{},{},{}", .{idx,s,e,z_cnt, total});
        switch (go_type) {
            .high => {
                if (z_cnt > total / 2) {
                    e = s + z_cnt - 1;
                } else {
                    s = s + z_cnt;
                }
            },
            .low => {
                if (z_cnt <= total / 2) {
                    e = s + z_cnt - 1;
                } else {
                    s = s + z_cnt;
                }
            },
        }
        high_bit += 1;
    }
    return try std.fmt.parseInt(u32, nums.items[s].items, 2);
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    var input_buffer: [1024]u8 = undefined;
    var nums = std.ArrayList(String).init(alloc);
    defer {
        for (nums.items) |item| item.deinit();
        nums.deinit();
    }

    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day3.txt"});
    defer line_iter.deinit();

    while (try line_iter.next()) |line| {
        var entry = String.init(alloc);
        errdefer entry.deinit();
        _ = try entry.writer().write(line);
        try nums.append(entry);
    }

    std.sort.sort(String, nums.items, {}, utils.alphabeticalArrayLists);

    const first = try go(nums, GoType.high);
    const second = try go(nums, GoType.low);

    std.debug.print("Nice: ({},{} = {})", .{first, second, first*second});
}