// Multi Dimensional Slices in Zig
// Sort of akin to ndarrays in Python's numpy
//
// Based on:
// https://gist.github.com/AssortedFantasy/f57ebe9c2b5c71081db345a7372d6a38

const std = @import("std");
const runtime_safety = std.debug.runtime_safety;
const mem = std.mem;
const testing = std.testing;

const NDSliceErrors = error{
    InsufficientBufferSize,
    ZeroLengthDimensionsNotSupported,
    IndexOutOfBounds,
};

pub const MemoryOrdering = enum {
    /// Least Signficant dimension last: [z, y, x] where consecutive x's are contiguous
    row_major,
    /// Least Signficant dimension first: [z, y, x] where consecutive z's are contiguous
    col_major,
};

/// N Dimensional Slice over an arbitary bit of linear memory
/// See test for usage
pub fn NDSlice(comptime T: type, comptime N: comptime_int, comptime memory_order: MemoryOrdering) type {
    return struct {
        const Self = @This();

        /// Length in each dimension {x0, x1, x2, ... xN-1}
        shape: [N]usize,

        /// Underlying memory used to store the individual items
        /// Is shrunk to the required size (buffer.len will yield number of elements)
        items: []T,

        pub const order = memory_order;

        // Memory used has to be passed in.
        pub fn init(shape: [N]usize, buffer: []T) !Self {
            var num_items: usize = 1;
            for (shape) |s| {
                num_items *= s;
            }
            if (num_items > buffer.len) return NDSliceErrors.InsufficientBufferSize;
            if (num_items == 0) return NDSliceErrors.ZeroLengthDimensionsNotSupported;

            return Self{
                .shape = shape,
                .items = buffer[0..num_items],
            };
        }

        /// Computes the linear index of an element
        pub fn lid(self: Self, index: [N]usize) !usize {
            if (runtime_safety) {
                for (index, 0..) |index_i, i| {
                    if (index_i >= self.shape[i]) return NDSliceErrors.IndexOutOfBounds;
                }
            }

            return switch (order) {
                .row_major => blk: {
                    // Linear index = ( ... ((i0*s1 + i1)*s2 + i2)*s3 + ... )*s(N-1) + i(N-1)
                    var linear_index = index[0];

                    comptime var i = 1;
                    inline while (i < N) : (i += 1) {
                        linear_index = linear_index * self.shape[i] + index[i]; // Single fused multiply add
                    }

                    break :blk linear_index;
                },
                .col_major => blk: {
                    // Linear index = i0 + s0*(i1 + s1*(i2 + s2*(...(i(N-2) + s(N-2)*i(N-1)) ... ))
                    var linear_index = index[N - 1];

                    comptime var i = N - 2;
                    inline while (i >= 0) : (i -= 1) {
                        linear_index = linear_index * self.shape[i] + index[i]; // Single fused mutiply add
                    }

                    break :blk linear_index;
                },
            };
        }

        pub fn at(self: Self, index: [N]usize) !T {
            return self.items[try self.lid(index)];
        }
    };
}

test "Simple Slice" {
    // This creates a 2D slice type we can use to represent images, its a MxN slice of triplets of RGB values
    const ImageSlice = NDSlice([3]u8, 2, .row_major);

    // This is a buffer, we need to create a buffer to put the slice on
    var image_buffer = [_][3]u8{.{ 0, 0, 0 }} ** 30; // 6x5 image (width X height)

    // This slice is created over that buffer.
    const image = try ImageSlice.init(.{ 5, 6 }, &image_buffer);

    // Use 'lid' to get the linear index of an element and 'items' to access the underlying memory
    try testing.expect(mem.eql(u8, &image.items[try image.lid(.{ 0, 0 })], &.{ 0, 0, 0 }));
    image.items[try image.lid(.{ 0, 0 })] = .{ 1, 2, 3 };
    try testing.expect(mem.eql(u8, &image.items[try image.lid(.{ 0, 0 })], &.{ 1, 2, 3 }));

    // You can also use 'at' to get the value at a particular index
    image.items[try image.lid(.{ 1, 1 })] = .{ 50, 50, 50 };
    try testing.expect(mem.eql(u8, &try image.at(.{ 1, 1 }), &.{ 50, 50, 50 }));

    // Check the shape
    try testing.expect(mem.eql(usize, &image.shape, &.{ 5, 6 }));

    // Check the number of items
    try testing.expect(image.items.len == 5 * 6);
}
