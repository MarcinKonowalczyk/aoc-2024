const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const stdin = @import("stdin");

const utils = @import("utils.zig");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    const lines = try stdin.splitLines(alloc, in);
    defer alloc.free(lines);

    for (lines) |line| {
        const values = try utils.parse_line(line);
        print("{}\n", .{values});
    }

    const answer = 99;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
