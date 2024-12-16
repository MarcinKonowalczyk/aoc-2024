const std = @import("std");

const Entry = struct {
    a: u8,
    b: [3]i64,
};

pub fn main() !void {
    // const allocator = std.heap.page_allocator;
    const allocator: std.mem.Allocator = std.heap.page_allocator;

    var entries = std.ArrayList(Entry).init(allocator);
    defer entries.deinit();

    for (0..3) |i| {
        const entry = Entry{ .a = @intCast(i), .b = [_]i64{ 1, 2, 3 } };
        std.debug.print("{any}\n", .{entry});
        try entries.append(entry);
    }

    for (entries.items) |entry| {
        std.debug.print("{any}\n", .{entry});
    }
}
