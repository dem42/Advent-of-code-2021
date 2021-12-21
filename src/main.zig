const std = @import("std");
const problem = @import("day21.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const has_leaked = gpa.deinit();
        if (has_leaked) {
            std.debug.print("The GPA has leaked", .{});
        }
    }

    const allocator = &gpa.allocator;

    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();

    // const allocator = &arena.allocator;

    try problem.solve(allocator);
}
