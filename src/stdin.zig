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

/// Copy a string into a newly allocated buffer. The caller is responsible for freeing the memory.
fn strcopy(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
    const result = try alloc.alloc(u8, s.len);
    std.mem.copyForwards(u8, result, s);
    return result;
}

/// Split the input into lines, strip the newline character, and return a list of lines.
pub fn splitLines(allocator: std.mem.Allocator, input: []u8) ![][]u8 {
    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

    var start: usize = 0;
    for (input, 0..) |c, i| {
        if (c == '\n') {
            const line = input[start..i];
            try lines.append(try strcopy(allocator, line));
            start = i + 1;
        }
    }

    return try lines.toOwnedSlice();
}

// lines for testing
const _: []u8 = "lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua" ++
    "ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat duis aute irure" ++
    "dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur excepteur sint occaecat cupidatat" ++
    "non proident sunt in culpa qui officia deserunt mollit anim id est laborum";
