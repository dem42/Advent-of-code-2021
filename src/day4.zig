const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;

pub fn solve(alloc: *std.mem.Allocator) !void {
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day4.txt"});
    defer line_iter.deinit();

    const BingoCell = struct {
        x: u4,
        y: u4,
        called: bool,
    };

    const BingoTable = struct {
        won: bool,
        map: std.AutoHashMap(u16, BingoCell),
        col_cnt: [5]u4,
        row_cnt: [5]u4,
    };

    var called_nums = std.ArrayList(u16).init(alloc);
    defer called_nums.deinit();

    var bingo_tables = std.ArrayList(BingoTable).init(alloc);
    defer {
        for (bingo_tables.items) |*table| table.map.deinit();
        bingo_tables.deinit();
    }

    var input_block_idx: usize = 0;
    var bingo_lines_read: u4 = 0;

    while (try line_iter.next()) |line| {
        if (std.mem.eql(u8, line, ""))
            continue;

        if (input_block_idx == 0) {
            var token_iter = std.mem.tokenize(line, ",");
            while (token_iter.next()) |tok| {
                const num = try std.fmt.parseInt(u16, tok, 10);
                try called_nums.append(num);
            }
            input_block_idx += 1;
        } else {
            if (bingo_lines_read == 0) {
                var bingo_table = BingoTable {
                    .won = false,
                    .map = std.AutoHashMap(u16, BingoCell).init(alloc),
                    .col_cnt = [_]u4{0} ** 5,
                    .row_cnt = [_]u4{0} ** 5,
                };
                try bingo_tables.append(bingo_table);
            }

            var col_idx: u4 = 0;
            var token_iter = std.mem.tokenize(line, " ");
            while (token_iter.next()) |tok| {
                const num = try std.fmt.parseInt(u16, tok, 10);
                try bingo_tables.items[input_block_idx - 1].map.put(num, BingoCell{.x = col_idx, .y = bingo_lines_read, .called = false});
                col_idx += 1;
            }
            bingo_lines_read += 1;

            if (bingo_lines_read == 5) {
                input_block_idx += 1;
                bingo_lines_read = 0;
            }
        }
    }

    var boards_remain = bingo_tables.items.len;

    for (called_nums.items) |called_num| {
        for (bingo_tables.items) |*table| {
            if (table.won)
                continue;

            if (table.map.contains(called_num)) {
                var cell_ptr = table.map.getPtr(called_num).?;
                cell_ptr.*.called = true;
                table.col_cnt[cell_ptr.*.x] += 1;
                table.row_cnt[cell_ptr.*.y] += 1;
                if (table.col_cnt[cell_ptr.*.x] == 5 or table.row_cnt[cell_ptr.*.y] == 5) {
                    table.won = true;
                    boards_remain -= 1;

                    if (boards_remain == 0) {
                        var result: u64 = 0;
                        var iter = table.map.iterator();
                        while (iter.next()) |entry| {
                            //std.log.info("Table entry: {} -> {},{},{}", .{entry.key_ptr.*, entry.value_ptr.x, entry.value_ptr.y, entry.value_ptr.called});
                            if (!entry.value_ptr.called) {
                                result += entry.key_ptr.*;
                            }
                        }
                        result *= called_num;
                        std.debug.print("Bingo: {} with called number {}", .{result, called_num});
                        return;
                    }
                }
            }
        }
    }

    std.debug.print("Failed to bingo", .{});
}