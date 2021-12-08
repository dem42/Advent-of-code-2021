const std = @import("std");

pub fn solve(alloc: *std.mem.Allocator) !void {
    //const input = std.io.getStdIn();
    const input = try std.fs.cwd().openFile("inputs/day2.txt", .{ .read = true });
    defer input.close();

    var input_buffer: [1024]u8 = undefined;
    var nums = std.ArrayList(u32).init(alloc);
    defer nums.deinit();

    var stream = input.reader();

    var pos_x: i32 = 0;
    var pos_y: i32 = 0;
    var aim: i32 = 0;

    while (try stream.readUntilDelimiterOrEof(&input_buffer, '\n')) |line| {
        const trimmed_line = std.mem.trimRight(u8, line, "\r");
        var token_iter = std.mem.tokenize(trimmed_line, " ");
        const move_type = token_iter.next() orelse "";
        const num = try std.fmt.parseInt(i32, token_iter.next() orelse "", 10);
        if (std.mem.eql(u8, move_type, "forward")) {
            pos_x += num;
            pos_y += num * aim;
        } else if (std.mem.eql(u8, move_type, "down")) {
            aim += num;
        } else if (std.mem.eql(u8, move_type, "up")) {
            aim -= num;
        } else {
            unreachable;
        }
    }

    std.debug.print("Position: ({},{} = {})", .{pos_x, pos_y,pos_x*pos_y});
}