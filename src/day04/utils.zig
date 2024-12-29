const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const Tuple = std.meta.Tuple;

pub fn in2shape(in: []const u8) !Tuple(&.{ usize, usize }) {
    var M: usize = 0;
    var N: usize = 0;
    if (in.len == 0) {
        return .{ M, N };
    }

    // find the first newline
    var i: usize = 0;
    while (i < in.len) : (i += 1) {
        if (in[i] == '\n') {
            M += 1;
            break;
        }
        N += 1;
    }
    i += 1;

    // find the rest of the newlines
    while (i < in.len) : (i += 1) {
        if (in[i] == '\n') {
            M += 1;
        }
    }

    // if the last line doesn't end with a newline, add it
    if (in[in.len - 1] != '\n') {
        M += 1;
    }

    return .{ M, N };
}

fn test_in2shape(input: []const u8, expected: Tuple(&.{ usize, usize })) !void {
    const actual = try in2shape(input);
    // print("test {any} == {any}\n", .{ actual, expected });
    try testing.expectEqual(actual, expected);
}

test in2shape {
    const t = test_in2shape;
    try t("abc\n", .{ 1, 3 });
    try t("abc", .{ 1, 3 });
    try t("a\nb\nc\n", .{ 3, 1 });
    try t("a\nb\nc", .{ 3, 1 });
    try t("\n\n\n", .{ 3, 0 });
    try t("", .{ 0, 0 });
    try t("abc\nabc\nabc\n", .{ 3, 3 });
}

/// Move all the instances of `delim` to the end of the array
pub fn sortDelimiter(in: []u8, delim: u8) void {
    var i: usize = 0;
    var j: usize = 0;
    while (j < in.len) : ({
        i += 1;
        j += 1;
    }) {
        // Move j to the next non-delim character
        while (j < in.len and in[j] == delim) : (j += 1) {}
        if (j >= in.len) {
            break;
        }
        in[i] = in[j];
    }

    // Fill the rest of the array with the delim
    while (i < in.len) : (i += 1) {
        in[i] = delim;
    }
    return;
}

fn test_sortDelimiter(input: []const u8, delim: u8, expected: []const u8) !void {
    const allocator = testing.allocator;
    const input_2 = try allocator.alloc(u8, input.len);
    defer allocator.free(input_2);
    std.mem.copyForwards(u8, input_2, input);

    sortDelimiter(input_2, delim);

    try testing.expect(std.mem.eql(u8, input_2, expected));
}

test sortDelimiter {
    const t = test_sortDelimiter;
    try t("abcZZZdefZghiZ", 'Z', "abcdefghiZZZZZ");
    try t("abcZZZdefZghiZ", 'H', "abcZZZdefZghiZ");
    try t("abcZZZdefZghi", 'Z', "abcdefghiZZZZ");
    try t("abcZZZZZZZZZZZZZZdefZghiZ", 'Z', "abcdefghiZZZZZZZZZZZZZZZZ");
}
