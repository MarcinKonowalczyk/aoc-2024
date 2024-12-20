const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

pub fn get_answer() u8 {
    return 0;
}

test "test getting answer" {
    try testing.expect(get_answer() == 49);
}
