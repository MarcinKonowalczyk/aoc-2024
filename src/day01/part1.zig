const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const stdin = @import("stdin");

const utils = @import("utils.zig");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    var it = std.mem.tokenizeAny(u8, in, " \n");

    const id_utype = u16;
    const id_type = @Type(.{
        .Int = .{
            .bits = @typeInfo(id_utype).Int.bits * 2,
            .signedness = .signed,
        },
    });

    // print("id_utype: {}\n", .{id_utype});
    // print("id_type: {}\n", .{id_type});

    var ids = std.ArrayList(id_utype).init(alloc);
    while (it.next()) |token| {
        const value = try std.fmt.parseInt(id_utype, token, 10);
        try ids.append(value);
    }

    const id_max = std.math.maxInt(id_utype);
    var smallest_rgt: id_utype = id_max;
    var smallest_lft: id_utype = id_max;
    var second_smallest_rgt: id_utype = id_max;
    var second_smallest_lft: id_utype = id_max;
    for (ids.items, 0..) |id, i| {
        if (i % 2 == 0) { // evens
            if (id < smallest_lft) {
                second_smallest_lft = smallest_lft;
                smallest_lft = id;
            } else if (id < second_smallest_lft) {
                second_smallest_lft = id;
            }
        } else { // odds
            if (id < smallest_rgt) {
                second_smallest_rgt = smallest_rgt;
                smallest_rgt = id;
            } else if (id < second_smallest_rgt) {
                second_smallest_rgt = id;
            }
        }
    }

    const smallest_distance = @abs(@as(id_type, smallest_rgt) - @as(id_type, smallest_lft));
    const second_smallest_distance = @abs(@as(id_type, second_smallest_rgt) - @as(id_type, second_smallest_lft));

    print("smallest_distance: {}\n", .{smallest_distance});
    print("second_smallest_distance: {}\n", .{second_smallest_distance});

    //     .print(
    //     "smallest_lft: {}, second_smallest_lft: {}, smallest_rgt: {}, second_smallest_rgt: {}\n",
    //     .{ smallest_lft, second_smallest_lft, smallest_rgt, second_smallest_rgt },
    // );
    // const lines = try stdin.splitLines(alloc, in);
    // defer alloc.free(lines);

    // for (lines) |line| {
    //     const values = try utils.parse_line(line);
    //     print("{}\n", .{values});
    // }

    const answer = 99;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
