const std = @import("std");
const print = std.debug.print;
const runtime_safety = std.debug.runtime_safety;
const mem = std.mem;
const testing = std.testing;

const RaggedSliceErrors = error{IndexOutOfBounds};

/// A slice of ragged rows. All the rows are contiguous in memory and can be deallocated all at once.
/// The widths of each of the rows can be different.
pub fn RaggedSlice(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Underlying memory used to store the individual items
        buffer_items: []T,

        /// Widths of each row
        buffer_widths: []usize,

        N_elements: usize,
        N_rows: usize,

        elements_capacity: usize,
        rows_capacity: usize,

        allocator: mem.Allocator,

        pub fn init(allocator: mem.Allocator) !Self {
            return Self{
                .buffer_items = try allocator.alloc(T, 0),
                .buffer_widths = try allocator.alloc(usize, 0),
                .allocator = allocator,
                .N_elements = 0,
                .N_rows = 0,
                .elements_capacity = 0,
                .rows_capacity = 0,
            };
        }

        pub fn items(self: Self) []const T {
            return self.buffer_items[0..self.N_elements];
        }

        pub fn widths(self: Self) []const usize {
            return self.buffer_widths[0..self.N_rows];
        }

        pub fn appendRow(self: *Self, row: []const T) !void {
            const M = row.len;

            const element_capacity = self.elements_capacity - self.N_elements;
            if (element_capacity < M) {
                // Expand the items array
                const new_size: usize = switch (self.elements_capacity) {
                    0 => @max(1, M),
                    else => @max(self.elements_capacity + M, self.elements_capacity * 2),
                };
                const new_items = try self.allocator.realloc(self.buffer_items, new_size);
                self.buffer_items = new_items;
                self.elements_capacity = new_size;
            }

            const width_capacity = self.rows_capacity - self.N_rows;
            if (width_capacity < 1) {
                // Expand the widths array
                const new_size: usize = switch (self.rows_capacity) {
                    0 => 1,
                    else => self.rows_capacity * 2,
                };
                const new_widths = try self.allocator.realloc(self.buffer_widths, new_size);
                self.buffer_widths = new_widths;
                self.rows_capacity = new_size;
            }

            @memcpy(self.buffer_items[self.N_elements..(self.N_elements + M)], row);

            self.buffer_widths[self.N_rows] = M;
            self.N_elements += M;
            self.N_rows += 1;
        }

        /// Computes the linear index of an element
        pub fn linearIndex(self: Self, index: [2]usize) !usize {
            if (runtime_safety) {
                if (index[0] >= self.N_rows) return RaggedSliceErrors.IndexOutOfBounds;
                if (index[1] >= self.buffer_widths[index[0]]) return RaggedSliceErrors.IndexOutOfBounds;
            }

            var linear_index: usize = 0;
            for (0..index[0]) |i| {
                linear_index += self.buffer_widths[i];
            }
            linear_index += index[1];

            return linear_index;
        }

        pub fn at(self: Self, index: [2]usize) !T {
            return self.buffer_items[try self.linearIndex(index)];
        }

        // Computes the ragged index of an element
        pub fn raggedIndex(self: Self, linear_index: usize) ![2]usize {
            if (runtime_safety) {
                if (linear_index >= self.N_elements) return RaggedSliceErrors.IndexOutOfBounds;
            }

            var row: usize = 0;
            var _linear_index: usize = linear_index;
            while (row < self.N_rows) {
                if (_linear_index < self.buffer_widths[row]) {
                    return .{ row, _linear_index };
                }
                _linear_index -= self.buffer_widths[row];
                row += 1;
            }

            return RaggedSliceErrors.IndexOutOfBounds;
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.buffer_items);
            self.allocator.free(self.buffer_widths);
        }

        // Item iterator with indices
        pub const Item = struct {
            value_ptr: *const T,
            row: usize = 0,
            column: usize = 0,
        };

        pub const ItemIterator = struct {
            rs: *const Self,
            index: usize = 0,
            row: usize = 0,
            column: usize = 0,

            pub fn next(it: *ItemIterator) ?Item {
                std.debug.assert(it.index <= it.rs.N_elements);
                if (it.rs.N_elements == 0) return null; // no elements
                if (it.index == it.rs.N_elements) return null; // end of iteration

                // print("index: {d}, row: {d}, column: {d}\n", .{ it.index, it.row, it.column });
                const value = &it.rs.items()[it.index];
                const entry = Item{
                    .value_ptr = value,
                    .row = it.row,
                    .column = it.column,
                };

                it.index += 1;
                it.column += 1;
                // NOTE: while to skip empty rows
                while (it.row < it.rs.N_rows and it.column == it.rs.widths()[it.row]) {
                    it.row += 1;
                    it.column = 0;
                }
                return entry;
            }
        };

        pub fn iterItems(self: *const Self) ItemIterator {
            return .{ .rs = self };
        }

        pub const RowIterator = struct {
            rs: *const Self,
            index: usize = 0,
            row: usize = 0,

            pub fn next(it: *RowIterator) ?[]const T {
                if (it.rs.N_rows == 0) return null; // no rows
                if (it.row == it.rs.N_rows) return null; // end of iteration

                const width = it.rs.widths()[it.row];
                const row = it.rs.buffer_items[it.index..(it.index + width)];

                it.index += width;
                it.row += 1;

                return row;
            }
        };

        pub fn iterRows(self: *const Self) RowIterator {
            return .{ .rs = self };
        }
    };
}

test RaggedSlice {
    const allocator = testing.allocator;

    var rs = try RaggedSlice(u8).init(allocator);
    defer rs.deinit();

    try rs.appendRow(&.{ 1, 2, 3 });
    try rs.appendRow(&.{ 99, 99 });
    try rs.appendRow(&.{}); // Empty row
    try rs.appendRow(&.{ 4, 5, 6, 7 });

    // Print raw buffers
    // print("{any}\n", .{rs.buffer_items});
    // print("{any}\n", .{rs.buffer_widths});

    // Check the slice has the expected values
    try testing.expect(rs.N_elements == 9);
    try testing.expect(rs.N_rows == 4);
    const expected_items = &.{ 1, 2, 3, 99, 99, 4, 5, 6, 7 };
    const expected_widths = &.{ 3, 2, 0, 4 };
    try testing.expect(mem.eql(u8, rs.items(), expected_items));
    try testing.expect(mem.eql(usize, rs.widths(), expected_widths));

    try testing.expect(try rs.at(.{ 0, 0 }) == 1);
    try testing.expect(try rs.at(.{ 0, 1 }) == 2);
    try testing.expect(try rs.at(.{ 0, 2 }) == 3);
    try testing.expectError(RaggedSliceErrors.IndexOutOfBounds, rs.at(.{ 0, 3 }));

    try testing.expect(try rs.at(.{ 1, 0 }) == 99);
    try testing.expect(try rs.at(.{ 1, 1 }) == 99);
    try testing.expectError(RaggedSliceErrors.IndexOutOfBounds, rs.at(.{ 1, 2 }));

    // Empty row
    try testing.expectError(RaggedSliceErrors.IndexOutOfBounds, rs.at(.{ 2, 0 }));

    try testing.expect(try rs.at(.{ 3, 0 }) == 4);
    try testing.expect(try rs.at(.{ 3, 1 }) == 5);
    try testing.expect(try rs.at(.{ 3, 2 }) == 6);
    try testing.expect(try rs.at(.{ 3, 3 }) == 7);
    try testing.expectError(RaggedSliceErrors.IndexOutOfBounds, rs.at(.{ 3, 4 }));

    try testing.expectError(RaggedSliceErrors.IndexOutOfBounds, rs.at(.{ 4, 0 }));

    // Test linear index
    try testing.expect(try rs.linearIndex(.{ 0, 0 }) == 0);
    try testing.expect(try rs.linearIndex(.{ 0, 1 }) == 1);
    try testing.expect(try rs.linearIndex(.{ 0, 2 }) == 2);
    try testing.expectError(RaggedSliceErrors.IndexOutOfBounds, rs.linearIndex(.{ 0, 3 }));
    // etc ...

    // Test ragged index
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(0), &.{ 0, 0 }));
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(1), &.{ 0, 1 }));
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(2), &.{ 0, 2 }));
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(3), &.{ 1, 0 }));
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(4), &.{ 1, 1 }));
    // Empty row
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(5), &.{ 3, 0 }));
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(6), &.{ 3, 1 }));
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(7), &.{ 3, 2 }));
    try testing.expect(mem.eql(usize, &try rs.raggedIndex(8), &.{ 3, 3 }));
    try testing.expectError(RaggedSliceErrors.IndexOutOfBounds, rs.raggedIndex(9));

    // Test iterators
    var it = rs.iterItems();

    var collected_values: [9]u8 = .{255} ** 9;
    var collected_rows: [9]usize = .{255} ** 9;
    var collected_columns: [9]usize = .{255} ** 9;

    var i: usize = 0;
    while (it.next()) |item| : (i += 1) {
        collected_values[i] = item.value_ptr.*;
        collected_rows[i] = item.row;
        collected_columns[i] = item.column;
    }

    try testing.expect(i == 9);

    try testing.expect(mem.eql(u8, &collected_values, expected_items));

    const expected_rows = &.{ 0, 0, 0, 1, 1, 3, 3, 3, 3 };
    const expected_columns = &.{ 0, 1, 2, 0, 1, 0, 1, 2, 3 };

    try testing.expect(mem.eql(usize, &collected_rows, expected_rows));
    try testing.expect(mem.eql(usize, &collected_columns, expected_columns));

    var rit = rs.iterRows();

    var row = rit.next();
    try testing.expect(row != null);
    try testing.expect(row.?.len == 3);
    try testing.expect(std.mem.eql(u8, row.?, &.{ 1, 2, 3 }));

    row = rit.next();
    try testing.expect(row != null);
    try testing.expect(row.?.len == 2);
    try testing.expect(std.mem.eql(u8, row.?, &.{ 99, 99 }));

    row = rit.next();
    try testing.expect(row != null);
    try testing.expect(row.?.len == 0);
    try testing.expect(std.mem.eql(u8, row.?, &.{}));

    row = rit.next();
    try testing.expect(row != null);
    try testing.expect(row.?.len == 4);
    try testing.expect(std.mem.eql(u8, row.?, &.{ 4, 5, 6, 7 }));

    row = rit.next();
    try testing.expect(row == null);
}
