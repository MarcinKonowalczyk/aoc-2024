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

    const count = try find_xmases(N, in, visited);

    if (visited) |v| {
        const repr = try utils.slice_2d_repr(bool, alloc, v.items, .{ N, N });
        defer alloc.free(repr);
        print("{s}\n", .{repr});
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{count});
}

fn find_xmases(
    N: usize,
    in: ndslice.NDSlice(u8, 2, .row_major),
    visited: ?ndslice.NDSlice(bool, 2, .row_major),
) !usize {
    if (visited) |v| {
        print("visited: {any}\n", .{v});
    } else {
        print("visited: null\n", .{});
    }
    var count: usize = 0;
    for (0..N) |i| {
        for (0..N) |j| {
            const value = try in.at(.{ i, j });
            if (value == 'X') {
                // Check vertical XMASes
                if (i + 3 <= N - 1) {
                    if (try in.at(.{ i + 1, j }) == 'M' and
                        try in.at(.{ i + 2, j }) == 'A' and
                        try in.at(.{ i + 3, j }) == 'S')
                    {
                        count += 1;
                        if (visited) |v| {
                            try v.put(.{ i, j }, true);
                            try v.put(.{ i + 1, j }, true);
                            try v.put(.{ i + 2, j }, true);
                            try v.put(.{ i + 3, j }, true);
                        }
                    }
                }

                if (i >= 3) {
                    if (try in.at(.{ i - 1, j }) == 'M' and
                        try in.at(.{ i - 2, j }) == 'A' and
                        try in.at(.{ i - 3, j }) == 'S')
                    {
                        count += 1;
                        if (visited) |v| {
                            try v.put(.{ i, j }, true);
                            try v.put(.{ i - 1, j }, true);
                            try v.put(.{ i - 2, j }, true);
                            try v.put(.{ i - 3, j }, true);
                        }
                    }
                }

                // Check horizontal XMASes
                if (j + 3 <= N - 1) {
                    if (try in.at(.{ i, j + 1 }) == 'M' and
                        try in.at(.{ i, j + 2 }) == 'A' and
                        try in.at(.{ i, j + 3 }) == 'S')
                    {
                        count += 1;
                        if (visited) |v| {
                            try v.put(.{ i, j }, true);
                            try v.put(.{ i, j + 1 }, true);
                            try v.put(.{ i, j + 2 }, true);
                            try v.put(.{ i, j + 3 }, true);
                        }
                    }
                }

                if (j >= 3) {
                    if (try in.at(.{ i, j - 1 }) == 'M' and
                        try in.at(.{ i, j - 2 }) == 'A' and
                        try in.at(.{ i, j - 3 }) == 'S')
                    {
                        count += 1;
                        if (visited) |v| {
                            try v.put(.{ i, j }, true);
                            try v.put(.{ i, j - 1 }, true);
                            try v.put(.{ i, j - 2 }, true);
                            try v.put(.{ i, j - 3 }, true);
                        }
                    }
                }

                // Check diagonal XMASes
                if (i + 3 <= N - 1 and j + 3 <= N - 1) {
                    // Down-right
                    if (try in.at(.{ i + 1, j + 1 }) == 'M' and
                        try in.at(.{ i + 2, j + 2 }) == 'A' and
                        try in.at(.{ i + 3, j + 3 }) == 'S')
                    {
                        count += 1;
                        if (visited) |v| {
                            try v.put(.{ i, j }, true);
                            try v.put(.{ i + 1, j + 1 }, true);
                            try v.put(.{ i + 2, j + 2 }, true);
                            try v.put(.{ i + 3, j + 3 }, true);
                        }
                    }
                }

                if (i >= 3 and j >= 3) {
                    // Up-left
                    if (try in.at(.{ i - 1, j - 1 }) == 'M' and
                        try in.at(.{ i - 2, j - 2 }) == 'A' and
                        try in.at(.{ i - 3, j - 3 }) == 'S')
                    {
                        count += 1;
                        if (visited) |v| {
                            try v.put(.{ i, j }, true);
                            try v.put(.{ i - 1, j - 1 }, true);
                            try v.put(.{ i - 2, j - 2 }, true);
                            try v.put(.{ i - 3, j - 3 }, true);
                        }
                    }
                }

                if (i + 3 <= N - 1 and j >= 3) {
                    // Down-left
                    if (try in.at(.{ i + 1, j - 1 }) == 'M' and
                        try in.at(.{ i + 2, j - 2 }) == 'A' and
                        try in.at(.{ i + 3, j - 3 }) == 'S')
                    {
                        count += 1;
                        if (visited) |v| {
                            try v.put(.{ i, j }, true);
                            try v.put(.{ i + 1, j - 1 }, true);
                            try v.put(.{ i + 2, j - 2 }, true);
                            try v.put(.{ i + 3, j - 3 }, true);
                        }
                    }
                }

                if (i >= 3 and j + 3 <= N - 1) {
                    // Up-right
                    if (try in.at(.{ i - 1, j + 1 }) == 'M' and
                        try in.at(.{ i - 2, j + 2 }) == 'A' and
                        try in.at(.{ i - 3, j + 3 }) == 'S')
                    {
                        count += 1;
                        if (visited) |v| {
                            try v.put(.{ i, j }, true);
                            try v.put(.{ i - 1, j + 1 }, true);
                            try v.put(.{ i - 2, j + 2 }, true);
                            try v.put(.{ i - 3, j + 3 }, true);
                        }
                    }
                }
            }
        }
    }

    return count;
}
