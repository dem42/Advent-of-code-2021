const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;

pub fn solve(alloc: *std.mem.Allocator) !void {
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day5.txt"});
    defer line_iter.deinit();

    var map: [1000][1000] u16 = [_][1000]u16{[_]u16{0} ** 1000} ** 1000;

    const Point = struct { x: i16, y: i16 };

    var cnt_gt_two: usize = 0;

    while (try line_iter.next()) |line| {
        if (std.mem.eql(u8, line, ""))
            continue;
        var split_iter = std.mem.tokenize(line, " ->,");
        const s = Point {
            .x = try std.fmt.parseInt(i16, split_iter.next().?, 10),
            .y = try std.fmt.parseInt(i16, split_iter.next().?, 10),
        };

        const e = Point {
            .x = try std.fmt.parseInt(i16, split_iter.next().?, 10),
            .y = try std.fmt.parseInt(i16, split_iter.next().?, 10),
        };

        const dx_signed = e.x - s.x;
        const dy_signed = e.y - s.y;
        const inc_dx: i16 = if (dx_signed < 0) -1 else if (dx_signed > 1) @as(i16, 1) else 0;
        const inc_dy: i16 = if (dy_signed < 0) -1 else if (dy_signed > 1) @as(i16, 1) else 0;

        const dx = std.math.absCast(dx_signed);
        const dy = std.math.absCast(dy_signed);

        if (dx != 0 and dy != 0 and dx != dy) {
            std.log.err("Unexpected dx,dy = {},{}", .{dx, dy});
            continue;
        }
        const dmax = std.math.max(dx, dy);

        var idx: u16 = 0;
        while (idx <= dmax) : (idx += 1) {
            const ny = @intCast(u16, s.y + inc_dy * @intCast(i16, idx));
            const nx = @intCast(u16, s.x + inc_dx * @intCast(i16, idx));
            map[ny][nx] += 1;
            if (map[ny][nx] == 2) {
                cnt_gt_two += 1;
            }
        }
    }

    std.debug.print("Res: {}", .{cnt_gt_two});
}