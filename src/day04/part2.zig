const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const stdin = @import("stdin");
const Tuple = std.meta.Tuple;
const utils = @import("utils.zig");

const ndslice = @import("nd_slice");

const VISITED = true;

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in_buffer = try stdin.readAllStdin(alloc);
    defer alloc.free(in_buffer);

    const shape = try utils.in2shape(in_buffer);
    if (shape.@"0" != shape.@"1") {
        return error.InvalidInput;
    }
    const N = shape.@"0";
    // print("N: {d}\n", .{N});

    utils.sortDelimiter(in_buffer, '\n');

    const in = try ndslice
        .NDSlice(u8, 2, .row_major)
        .init(.{ N, N }, in_buffer);

    var visited_buffer: ?[]bool = null;
    if (VISITED) {
        visited_buffer = try alloc.alloc(bool, N * N);
        @memset(visited_buffer.?, false);
    }
    defer {
        if (visited_buffer) |buf| {
            alloc.free(buf);
        }
    }

    var visited: ?ndslice.NDSlice(bool, 2, .row_major) = null;
    if (VISITED) {
        visited = try ndslice
            .NDSlice(bool, 2, .row_major)
            .init(.{ N, N }, visited_buffer.?);
    }

    const count = try find_x_mases(N, in, visited);

    if (visited) |v| {
        const repr = try utils.slice_2d_repr(bool, alloc, v.items, .{ N, N });
        defer alloc.free(repr);
        print("{s}\n", .{repr});
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{count});
}

/// Find X-MAS'es. There is one 4-way symmetric case
///
///   M.S
///   .A.
///   M.S
///
fn find_x_mases(
    N: usize,
    in: ndslice.NDSlice(u8, 2, .row_major),
    visited: ?ndslice.NDSlice(bool, 2, .row_major),
) !usize {
    var count: usize = 0;
    for (1..N - 1) |i| {
        for (1..N - 1) |j| {
            const value = try in.at(.{ i, j });
            if (value == 'A') {
                const tl = try in.at(.{ i - 1, j - 1 });
                const tr = try in.at(.{ i - 1, j + 1 });
                const bl = try in.at(.{ i + 1, j - 1 });
                const br = try in.at(.{ i + 1, j + 1 });

                if ((tl == 'M' and bl == 'M' and tr == 'S' and br == 'S') or
                    (tl == 'M' and bl == 'S' and tr == 'M' and br == 'S') or
                    (tl == 'S' and bl == 'S' and tr == 'M' and br == 'M') or
                    (tl == 'S' and bl == 'M' and tr == 'S' and br == 'M'))
                {
                    count += 1;
                    if (visited) |v| {
                        try v.put(.{ i, j }, true);
                        try v.put(.{ i - 1, j - 1 }, true);
                        try v.put(.{ i + 1, j - 1 }, true);
                        try v.put(.{ i - 1, j + 1 }, true);
                        try v.put(.{ i + 1, j + 1 }, true);
                    }
                }
            }
        }
    }

    return count;
}
