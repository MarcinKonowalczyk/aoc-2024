const std = @import("std");
const testing = std.testing;
const print = std.debug.print;
const stdin = @import("stdin");

// const utils = @import("utils.zig");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    const id_type = u32;
    var it = std.mem.tokenizeAny(u8, in, " \n");
    var ids = std.ArrayList(id_type).init(alloc);
    while (it.next()) |token| {
        const value = try std.fmt.parseInt(id_type, token, 10);
        try ids.append(value);
    }

    // Frequency for all the numbers in the right list
    var frequency = std.AutoHashMap(id_type, u32).init(alloc);
    defer frequency.deinit();
    var i: usize = 1;
    while (i < ids.items.len) : (i += 2) {
        const id = ids.items[i];
        if (frequency.get(id)) |count| {
            try frequency.put(id, count + 1);
        } else {
            try frequency.put(id, 1);
        }
    }

    var sum: @Type(.{ .Int = .{
        .bits = @typeInfo(id_type).Int.bits * 2,
        .signedness = .unsigned,
    } }) = 0;

    i = 0;
    while (i < ids.items.len) : (i += 2) {
        const id = ids.items[i];
        const count = frequency.get(id) orelse 0;
        const score = count * id;
        // print("id: {}, count: {}, score: {}\n", .{ id, count, score });
        sum += score;
    }

    const answer = sum;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
