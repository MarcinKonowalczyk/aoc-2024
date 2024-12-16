const std = @import("std");
const print = std.debug.print;
const stdin = @import("stdin");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    const lines = try stdin.splitLines(alloc, in);
    defer alloc.free(lines);

    for (lines, 0..) |line, i| {
        print("{d}: {s}\n", .{ i, line });
    }

    const answer = -1;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
