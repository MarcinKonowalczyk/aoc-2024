const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const testing = std.testing;
const Tuple = std.meta.Tuple;

pub fn parse_line(line: []const u8) !Tuple(&.{ u16, u16 }) {
    var it = mem.tokenizeAny(u8, line, " ");
    var out: Tuple(&.{ u8, u8 }) = undefined;
    var i: usize = 0;
    while (it.next()) |token| {
        if (i == 0) {
            out.@"0" = try std.fmt.parseInt(u8, token, 10);
        } else if (i == 1) {
            out.@"1" = try std.fmt.parseInt(u8, token, 10);
        } else {
            return error.InvalidLine;
        }
        i += 1;
    }
    return out;
}

test "parse_line" {
    const line = "  1      88 ";
    const expected = .{ 1, 88 };
    const result = try parse_line(line);
    try testing.expectEqual(result, expected);
}
