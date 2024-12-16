const std = @import("std");
const testing = std.testing;

pub fn get_answer() u8 {
    return 49;
}

test "test greeting" {
    try testing.expect(get_answer() == 49);
}
