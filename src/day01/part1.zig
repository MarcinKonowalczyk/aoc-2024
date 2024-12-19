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

    const id_type = i32;

    // print("id_type: {}\n", .{id_type});
    // print("id_utype: {}\n", .{id_utype});

    var ids = std.ArrayList(id_type).init(alloc);
    while (it.next()) |token| {
        const value = try std.fmt.parseInt(id_type, token, 10);
        try ids.append(value);
    }

    // print("ids: {any}\n", .{ids.items});

    const Context = struct {
        items: []id_type,
        i: u1,

        pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
            return ctx.items[2 * a + ctx.i] < ctx.items[2 * b + ctx.i];
        }

        pub fn swap(ctx: @This(), a: usize, b: usize) void {
            return std.mem.swap(id_type, &ctx.items[2 * a + ctx.i], &ctx.items[2 * b + ctx.i]);
        }

        pub fn len(ctx: @This()) usize {
            return ctx.items.len / 2;
        }
    };

    // Sort i and odds in-place
    var ctx = Context{ .items = ids.items, .i = 0 };
    std.sort.insertionContext(0, ctx.len(), ctx);
    ctx.i = 1;
    std.sort.insertionContext(0, ctx.len(), ctx);

    // print("ids: {any}\n", .{ids.items});

    var sum: @Type(.{ .Int = .{
        .bits = @typeInfo(id_type).Int.bits,
        .signedness = .unsigned,
    } }) = 0;

    var i: usize = 0;
    while (i < ids.items.len) : (i += 2) {
        const id1 = ids.items[i];
        const id2 = ids.items[i + 1];
        const diff = @abs(id1 - id2);
        // print("abs({d} - {d}) = {d}\n", .{ id1, id2, diff });
        sum += diff;
    }

    const answer = sum;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
