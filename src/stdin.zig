const std = @import("std");
// const print = std.debug.print;

const MAX_IDLE: comptime_int = 10; // Max number of idle loops before deciding we have no more input

/// Read all available bytes from stdin. The user is responsible for freeing the memory.
pub fn readAllStdin(allocator: std.mem.Allocator) ![]u8 {
    var buff = std.ArrayList(u8).init(allocator);
    defer buff.deinit();

    var idle: u8 = MAX_IDLE;
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
            try buff.ensureUnusedCapacity(n_readable);
            buff.items.len += fifo.read(buff.allocatedSlice()[buff.items.len..]);
            idle = MAX_IDLE; // We got some data! Reset the idle
        } else {
            _ = try poller.pollTimeout(loop_timeout) or break;
            idle -= 1;
        }
    }
    return buff.toOwnedSlice();
}

/// Split the input into lines, strip the newline character, and return a list of lines.
pub fn splitLines(allocator: std.mem.Allocator, input: []u8) ![][]u8 {
    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

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
