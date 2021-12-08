const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const print = utils.printAoc;

fn contains(pat: []const u8, dig: u8) bool {
    var found = false;
    for (pat) |dig2| {
        if (dig2 == dig) {
            found = true;
            break;
        }
    }
    return found;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    utils.g_part = .part2;
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/day8.txt"});
    defer line_iter.deinit();

    var arr = std.ArrayList(i32).init(alloc);
    defer arr.deinit();

    var uniq_pat: usize = 0;

    const digits = [_][7]u8{
        [_]u8{1, 1, 1, 0, 1, 1, 1},
        [_]u8{0, 0, 1, 0, 0, 1, 0},
        [_]u8{1, 0, 1, 1, 1, 0, 1},
        [_]u8{1, 0, 1, 1, 0, 1, 1},
        [_]u8{0, 1, 1, 1, 0, 1, 0},
        [_]u8{1, 1, 0, 1, 0, 1, 1},
        [_]u8{1, 1, 0, 1, 1, 1, 1},
        [_]u8{1, 0, 1, 0, 0, 1, 0},
        [_]u8{1, 1, 1, 1, 1, 1, 1},
        [_]u8{1, 1, 1, 1, 0, 1, 1},
    };

    var sum: usize = 0;
    while (try line_iter.next()) |line| {
        var decode: [10]u8 = [_]u8{10} ** 10;
        var five_found: usize = 0;
        var two_pat: [] const u8 = undefined;
        var three_pat: [] const u8 = undefined;
        var four_pat: [] const u8 = undefined;
        var five_pat: [3][] const u8 = undefined;
        var seven_pat: [] const u8 = undefined;

        var split_iter = std.mem.tokenize(line, "|");
        var sig_iter = std.mem.tokenize(split_iter.next().?, " ");

        five_found = 0;
        while (sig_iter.next()) |pat| {
            if (pat.len == 2) {
                two_pat = pat;
            } else if (pat.len == 3) {
                three_pat = pat;
            } else if (pat.len == 4) {
                four_pat = pat;
            } else if (pat.len == 5) {
                five_pat[five_found] = pat;
                five_found += 1;
            } else if (pat.len == 7) {
                seven_pat = pat;
            }
        }

        // method:
        // 3d minus 2d -> get val for a
        // 4d minus 7d -> find d/b digits (two)
        // more common of d/b digs in 5 is d less is b
        // c/f dig in 5 that has b is f the one that's not in is c
        // e/g dig in 5 that has b is g
        // only unset dig is e
        for (three_pat) |dig3| {
            if (!contains(two_pat, dig3)) {
                decode[dig3 - 'a'] = 0;
            }
        }

        for (four_pat) |dig4| {
            if (contains(two_pat, dig4))
                continue;

            var cnt: usize = 0;
            for (five_pat) |five_pat_item| {
                if (contains(five_pat_item, dig4)) {
                    cnt += 1;
                }
            }

            if (cnt == 1) {

                for (five_pat) |five_pat_item| {
                    if (!contains(five_pat_item, dig4))
                        continue;

                    if (cnt == 1) {
                        for (two_pat) |dig2| {
                            if (contains(five_pat_item, dig2)) {
                                decode[dig2 - 'a'] = 5;
                            } else {
                                decode[dig2 - 'a'] = 2;
                            }
                        }

                        for (seven_pat) |dig7| {
                            if (contains(five_pat_item, dig7) and decode[dig7 - 'a'] == 10) {
                                decode[dig7 - 'a'] = 6;
                            }
                        }
                    }
                }

                decode[dig4 - 'a'] = 1;
            } else {
                decode[dig4 - 'a'] = 3;
            }
        }

        for (decode) |*dval| {
            if (dval.* == 10) {
                dval.* = 4;
            }
        }

        for (decode) |dval, i|
            std.debug.print(" {}-{}", .{i, dval});
        std.debug.print("\n",.{});

        var output_vals_iter = std.mem.tokenize(split_iter.next().?, " ");
        var found: usize = 0;

        var res_dig: usize = 0;
        while (output_vals_iter.next()) |pat| {
            if (pat.len == 2 or pat.len == 3 or pat.len == 4 or pat.len == 7)
                uniq_pat += 1;

            var input_v: [7]u8 = [_]u8{0} ** 7;

            for (pat) |item| {
                input_v[decode[item-'a']] += 1;
            }

            for (digits) |digit, i| {
                if (std.mem.eql(u8, input_v[0..], digit[0..])) {
                    res_dig *= 10;
                    res_dig += i;
                    break;
                }
            }
        }
        std.debug.print("maps: {}\n", .{res_dig});
        sum += res_dig;
    }

    // part 1
    print(.part1, "Res {}\n", .{uniq_pat});

    // part 2
    print(.part2, "Res {}\n", .{sum});
}