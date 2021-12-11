const std = @import("std");
const utils = @import("utils.zig");
const String = utils.String;
const print = utils.printAoc;
const setDifference = utils.setDifference;
const StaticBitSet = std.StaticBitSet;

fn parseDigit(dig_str: []const u8) StaticBitSet(7) {
    var res = StaticBitSet(7).initEmpty();
    for (dig_str) |dig| res.set(dig - 'a');
    return res;
}

pub fn solve(alloc: *std.mem.Allocator) !void {
    utils.g_part = .part2;
    var line_iter = try utils.LineIterator(.{.buffer_size = 1024}).init(utils.InputType{.file = "../../inputs/archive/day8.txt"});
    defer line_iter.deinit();

    var arr = std.ArrayList(i32).init(alloc);
    defer arr.deinit();

    var uniq_pat: usize = 0;

    const digits = [10]StaticBitSet(7) {
        parseDigit("abcefg"),
        parseDigit("cf"),
        parseDigit("acdeg"),
        parseDigit("acdfg"),
        parseDigit("bcdf"),
        parseDigit("abdfg"),
        parseDigit("abdefg"),
        parseDigit("acf"),
        parseDigit("abcdefg"),
        parseDigit("abcdfg"),
    };

    var sum: usize = 0;
    while (try line_iter.next()) |line| {
        var decode: [10]u8 = [_]u8{10} ** 10;
        var five_found: usize = 0;
        var two_pat = StaticBitSet(7).initEmpty();
        var three_pat = StaticBitSet(7).initEmpty();
        var four_pat = StaticBitSet(7).initEmpty();
        var five_pat = [_]StaticBitSet(7) {StaticBitSet(7).initEmpty() } ** 3;
        var seven_pat = StaticBitSet(7).initEmpty();

        var split_iter = std.mem.tokenize(line, "|");
        var sig_iter = std.mem.tokenize(split_iter.next().?, " ");

        five_found = 0;
        while (sig_iter.next()) |pat| {
            if (pat.len == 2 ) {
                two_pat = parseDigit(pat);
            } else if (pat.len == 3) {
                three_pat = parseDigit(pat);
            } else if (pat.len == 4) {
                four_pat = parseDigit(pat);
            } else if (pat.len == 5) {
                five_pat[five_found] = parseDigit(pat);
                five_found += 1;
            } else if (pat.len == 7) {
                seven_pat = parseDigit(pat);
            }
        }

        // method:
        // 3d minus 2d -> get val for a
        const a_dig = setDifference(three_pat, two_pat).findFirstSet() orelse unreachable;
        decode[a_dig] = 0;

        // 4d minus 7d -> find d/b digits (two)
        const bd_digs = setDifference(four_pat, three_pat);
        var bd_digs_iter = bd_digs.iterator(.{});

        // more common of d/b digs in 5 is d less is b
        var b_dig: usize = 0;
        while (bd_digs_iter.next()) |dig| {
            var cnt: usize = 0;
            for (five_pat) |fp| {
                if (fp.isSet(dig)) cnt += 1;
            }
            if (cnt == 1) {
                b_dig = dig;
            }
            decode[dig] = if (cnt == 1) 1 else 3;
        }
        const five = for (five_pat) |fp| {
            if (fp.isSet(b_dig)) break fp;
        } else unreachable;

        // c/f dig in 5 that has b is f the one that's not in is c
        // e/g dig in 5 that has b is g
        const ce_digs = setDifference(seven_pat, five);
        const f_digs = setDifference(two_pat, ce_digs);
        const c_digs = setDifference(two_pat, f_digs);
        const e_digs = setDifference(ce_digs, c_digs);

        const f_dig = f_digs.findFirstSet() orelse unreachable;
        decode[f_dig] = 5;
        const c_dig = c_digs.findFirstSet() orelse unreachable;
        decode[c_dig] = 2;
        const e_dig = e_digs.findFirstSet() orelse unreachable;
        decode[e_dig] = 4;

        // only unset (val == 10) dig is e
        for (decode) |*dval| {
            if (dval.* == 10) dval.* = 6;
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

            var input = StaticBitSet(7).initEmpty();
            for (pat) |item| input.set(decode[item-'a']);

            for (digits) |digit, i| {
                if (std.meta.eql(input, digit)) {
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