const std = @import("std");
const print = std.debug.print;
const memcopy = std.mem.copyForwards;

fn readAllStdin(allocator: std.mem.Allocator) ![]u8 {
    // Buffer for reading from stdin in chunks
    const chunk = 128;
    var buff = try allocator.alloc(u8, chunk);

    var n: usize = 0;

    const max_idle = 10; // Max number of idle loops before deciding we have no more input
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
            // Read the data into the buffer
            const n_read = fifo.read(buff[n..]);
            n += n_read;
            idle = max_idle; // We got some data! Reset the idle
        } else {
            const keep_pooling = try poller.pollTimeout(loop_timeout);
            if (!keep_pooling) {
                break;
            }
            idle -= 1;
        }
    }
    buff = try allocator.realloc(buff, n); // trim the buffer to the actual size
    return buff;
}

// fn splitLines(allocator: std.mem.Allocator, input: []u8) ![][]u8 {
//     var lines = std.ArrayList([]u8).init(allocator);
//     defer lines.deinit();

//     var start: usize = 0;
//     for (input) |c, i| {
//         if (c == '\n') {
//             const line = input[start..i];
//             try lines.append(line);
//             start = i + 1;
//         }
//     }
//     return lines.items;
// }

pub fn main() !void {
    print("hello from main\n", .{});

    const allocator = std.heap.page_allocator;

    // Read from stdin
    const inbuff = try readAllStdin(allocator);
    defer allocator.free(inbuff);

    // print("--------------------------------------------\n{s}\n--------------------------------------------\n", .{inbuff});
    // print("The input is: {s}\n", .{inbuff2});

    // Check how many bytes are available to read in stdin
    // const available = try stdin.available();
    // print("Available: {d}\n", .{available});
    // const in = try stdin.readAllAlloc(allocator, 1024);
    // print("{s}", .{in});

    // Read the entire file into memory

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you

    const answer = 42;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
