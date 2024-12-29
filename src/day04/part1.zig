const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const stdin = @import("stdin");
const Tuple = std.meta.Tuple;
const utils = @import("utils.zig");

const ndslice = @import("nd_slice");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    const shape = try utils.in2shape(in);
    if (shape.@"0" != shape.@"1") {
        return error.InvalidInput;
    }
    const N = shape.@"0";
    print("N: {d}\n", .{N});

    utils.sortDelimiter(in, '\n');

    // This creates a 2D slice type we can use to represent images, its a MxN slice of triplets of RGB values
    const Slice = ndslice.NDSlice(u8, 2, .row_major);

    // This slice is created over that buffer.
    const in_slice = try Slice.init(.{ N, N }, in); // By convention height is the first dimension
    print("in_slice: {any}\n", .{in_slice});
    print("index: {any}\n", .{in_slice.lid(.{ 1, 0 })});

    // var lines_it = stdin.splitLines(in);
    // var i: usize = 0;

    // while (lines_it.next()) |line| : (i += 1) {
    //     print("{d}: {s}\n", .{ i, line });
    // }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{0});
}
