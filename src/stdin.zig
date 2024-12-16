const std = @import("std");

const max_idle = 10; // Max number of idle loops before deciding we have no more input

/// Read all available bytes from stdin. The user is responsible for freeing the memory.
pub fn readAllStdin(allocator: std.mem.Allocator) ![]u8 {
    const chunk = 128;
    var buff = try allocator.alloc(u8, chunk);

    var n: usize = 0;
    var idle: u8 = max_idle;
    const loop_timeout = 1000 * std.time.ns_per_us; // 1ms
    var poller = std.io.poll(
        allocator,
        enum { stdin },
        .{ .stdin = std.io.getStdIn() },
    );
    while (true) {
        _ = idle > 0 or break;
        const fifo = poller.fifo(.stdin);
        const n_readable = fifo.readableLength();
        if (n_readable > 0) {
            const n_to_read = @min(n_readable, chunk);
            while (n_to_read > buff.len - n) { // Expand the buffer if needed
                // NOTE: the expansion here does not need to be + chunk. this works though
                buff = try allocator.realloc(buff, buff.len + chunk);
            }
            n += fifo.read(buff[n..]);
            idle = max_idle; // We got some data! Reset the idle
        } else {
            _ = try poller.pollTimeout(loop_timeout) or break;
            idle -= 1;
        }
    }
    buff = try allocator.realloc(buff, n); // trim the buffer to the actual size
    return buff;
}

/// Split the input into lines, strip the newline character, and return a list of lines.
pub fn splitLines(allocator: std.mem.Allocator, input: []u8) ![][]u8 {
    var lines = std.ArrayList([]u8).init(allocator);

    var start: usize = 0;
    for (input, 0..) |c, i| {
        if (c == '\n') {
            const line = input[start..i];
            try lines.append(line);
            start = i + 1;
        }
    }

    return try lines.toOwnedSlice();
}
