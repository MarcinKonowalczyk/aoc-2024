const std = @import("std");
const print = std.debug.print;
const runtime_safety = std.debug.runtime_safety;
const mem = std.mem;
const testing = std.testing;

const Ragged2DSliceErrors = error{
    IndexOutOfBounds,
};

///
pub fn Ragged2DSlice(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Underlying memory used to store the individual items
        items: []T,

        /// Widths of each row
        widths: []usize,

        /// Total number of elements in the slice
        N: usize,

        /// How many T values this list can hold without allocating additional memory
        allocator: mem.Allocator,

        pub fn init(allocator: mem.Allocator) !Self {
            return Self{
                .items = try allocator.alloc(T, 0),
                .widths = try allocator.alloc(usize, 0),
                .allocator = allocator,
                .N = 0,
            };
        }

        /// Computes the linear index of an element
        pub fn at(self: Self, index: [2]usize) !usize {
            if (runtime_safety) {
                if (index[0] >= self.N) return Ragged2DSliceErrors.IndexOutOfBounds;
                if (index[1] >= self.widths[index[0]]) return Ragged2DSliceErrors.IndexOutOfBounds;
            }

            var linear_index: usize = 0;
            for (0..index[0]) |i| {
                print("i: {d}\n", .{i});
                linear_index += self.widths[i];
            }
            linear_index += index[1];

            return self.items[linear_index];
        }

        pub fn appendRow(self: *Self, row: []const T) !void {
            const M = row.len;
            if (M == 0) return;

            print("self.items.len: {d}\n", .{self.items.len});
            try self.maybeReallocItems(M);
            print("self.items.len: {d}\n", .{self.items.len});

            // print("self.widths.len: {d}\n", .{self.widths.len});
            try self.maybeReallocWidths();
            // print("self.widths.len: {d}\n", .{self.widths.len});

            mem.copyForwards(T, self.items[self.N..], row);
            self.widths[self.N] = M;
            self.N += M;
        }

        fn maybeReallocItems(self: *Self, new_item_size: usize) !void {
            const space_left = self.items.len - self.items.len;
            if (space_left < new_item_size) {
                const new_size: usize = switch (self.items.len) {
                    0 => @max(16, new_item_size),
                    else => @max(self.items.len + new_item_size, self.items.len * 2),
                };
                const new_items = try self.allocator.realloc(self.items, new_size);
                self.items = new_items;
            }
        }

        fn maybeReallocWidths(self: *Self) !void {
            const space_left = self.widths.len - self.widths.len;
            if (space_left < 1) {
                // const new_size = if (self.widths.len == 0) {
                //     1;
                // } else {
                //     self.widths.len * 2;
                // };
                const new_size: usize = switch (self.widths.len) {
                    0 => 1,
                    else => self.widths.len * 2,
                };
                self.widths = try self.allocator.realloc(self.widths, new_size);
            }
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.items);
            self.allocator.free(self.widths);
        }
    };
}

test "Simple Slice" {
    const allocator = testing.allocator;
    // defer allocator.deinit();
    // This creates a 2D slice type we can use to represent images, its a MxN slice of triplets of RGB values
    var my_slice = try Ragged2DSlice(u8).init(allocator);
    defer my_slice.deinit();

    try my_slice.appendRow(&.{ 1, 2, 3 });
    try my_slice.appendRow(&.{ 4, 5 });

    try testing.expect(try my_slice.at(.{ 0, 0 }) == 1);
    try testing.expect(try my_slice.at(.{ 0, 1 }) == 2);
    try testing.expect(try my_slice.at(.{ 0, 2 }) == 3);

    // // This is a buffer, we need to create a buffer to put the slice on
    // // var image_buffer = [_][3]u8{.{ 0, 0, 0 }} ** 30; // 6x5 image (width X height)

    // // // This slice is created over that buffer.
    // // const image = try ImageSlice.init(.{ 5, 6 }, &image_buffer); // By convention height is the first dimension

    // // You use .at() and .items() to access members.
    // image.items[try image.at(.{ 0, 0 })] = .{ 1, 2, 3 };
    // image.items[try image.at(.{ 1, 1 })] = .{ 50, 50, 50 };
    // image.items[try image.at(.{ 4, 5 })] = .{ 128, 255, 0 };
    // image.items[try image.at(.{ 2, 4 })] = .{ 100, 12, 30 };

    // You can get each of the individual dimensions with .shape
    // and for the total number of elements use .items.len
}
