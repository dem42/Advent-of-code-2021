const std = @import("std");

pub fn solve(alloc: *std.mem.Allocator) !void {
    //const input = std.io.getStdIn();
    const input = try std.fs.cwd().openFile("inputs/day1.txt", .{ .read = true });
    defer input.close();

    var input_buffer: [100]u8 = undefined;
    var nums = std.ArrayList(u32).init(alloc);
    var nums = std.ArrayList(u32).init(alloc);
    defer nums.deinit();
    var stream = input.reader();

    while (try stream.readUntilDelimiterOrEof(&input_buffer, '\n')) |line| {
        const trimmed_line = std.mem.trimRight(u8, line, "\r");
        const num = try std.fmt.parseInt(u32, trimmed_line, 10);
        try nums.append(num);
    }

    var increased: u32 = 0;
    var num_idx: u32 = 1;
    var csum: u32 = 0;
    const window = 3;

    while (num_idx < window) : (num_idx += 1) {
        csum += nums.items[num_idx];
    }

    while (num_idx < nums.items.len) : (num_idx += 1) {
        var nsum = csum - nums.items[num_idx - window] + nums.items[num_idx];
        if (csum < nsum) {
            increased += 1;
        }
        csum = nsum;
    }

    std.debug.print("Increased: {}", .{increased});
}