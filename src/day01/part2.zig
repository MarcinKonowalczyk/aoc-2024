const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const in = std.io.getStdIn();
    var buf = std.io.bufferedReader(in.reader());

    // Get the Reader interface from BufferedReader
    var r = buf.reader();

    const allocator = std.heap.page_allocator;
    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

    print("Reading from stdin\n", .{});
    while (true) {
        var msg_buf: [1024]u8 = undefined;
        // const n = r.pollTimeout(1000 * std.time.ns_per_us);
        // print("Poll returned: {d}\n", .{n});
        const line = try r.readUntilDelimiterOrEof(&msg_buf, '\n') orelse break;

        print("Read: {s}\n", .{line});

        try lines.append(line);
    }

    for (lines.items, 0..) |line, i| {
        std.debug.print("{d}: {s}\n", .{ i, line });
    }
}
