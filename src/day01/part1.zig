const std = @import("std");
const print = std.debug.print;
const stdin = @import("stdin");

pub fn main() !void {
    print("hello from main\n", .{});

    const allocator = std.heap.page_allocator;

    // Read from stdin
    const inbuff = try stdin.readAllStdin(allocator);
    defer allocator.free(inbuff);

    const lines = try stdin.splitLines(allocator, inbuff);
    defer allocator.free(lines);

    for (lines, 0..) |line, i| {
        print("{d}: {s}\n", .{ i, line });
    }

    const answer = 42;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
