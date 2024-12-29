const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const stdin = @import("stdin");
const Tuple = std.meta.Tuple;
const utils = @import("utils.zig");

const ndslice = @import("nd_slice");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in_buffer = try stdin.readAllStdin(alloc);
    defer alloc.free(in_buffer);

    const shape = try utils.in2shape(in_buffer);
    if (shape.@"0" != shape.@"1") {
        return error.InvalidInput;
    }
    const N = shape.@"0";
    print("N: {d}\n", .{N});

    utils.sortDelimiter(in_buffer, '\n');

    const in = try ndslice
        .NDSlice(u8, 2, .row_major)
        .init(.{ N, N }, in_buffer);

    // Keep track of visited cells
    const visited_buffer = try alloc.alloc(bool, N * N);
    defer alloc.free(visited_buffer);
    @memset(visited_buffer, false);

    const visited = try ndslice
        .NDSlice(bool, 2, .row_major)
        .init(.{ N, N }, visited_buffer);

    for (0..N) |i| {
        for (0..N) |j| {
            const value = try in.at(.{ i, j });
            if (value == 'X') {
                print("Found X at ({d}, {d})\n", .{ i, j });
                // Check vertical XMASes
                if (i + 3 <= N - 1) {
                    if (try in.at(.{ i + 1, j }) == 'M' and
                        try in.at(.{ i + 2, j }) == 'A' and
                        try in.at(.{ i + 3, j }) == 'S')
                    {
                        print("Found XMAS at ({d}, {d})\n", .{ i, j });
                        try visited.set_at(.{ i, j }, true);
                        try visited.set_at(.{ i + 1, j }, true);
                        try visited.set_at(.{ i + 2, j }, true);
                        try visited.set_at(.{ i + 3, j }, true);
                    }
                }

                // ...
            }

            // try visited.set_at(.{ i, j }, true);
            // print("i: {d}, j: {d}, value: {c}\n", .{ i, j, value });
        }
    }

    const repr = try utils.slice_2d_repr(bool, alloc, visited.items, .{ N, N });
    defer alloc.free(repr);
    print("{s}\n", .{repr});

    // print("0,0: {c}\n", .{try in.at(.{ 0, 0 })});
    // print("0,2: {c}\n", .{try in.at(.{ 0, 2 })});
    // print("2,0: {c}\n", .{try in.at(.{ 2, 0 })});

    // var lines_it = stdin.splitLines(in);
    // var i: usize = 0;

    // while (lines_it.next()) |line| : (i += 1) {
    //     print("{d}: {s}\n", .{ i, line });
    // }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{0});
}
