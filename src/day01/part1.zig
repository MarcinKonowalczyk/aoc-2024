const std = @import("std");
const print = std.debug.print;
const memcopy = std.mem.copyForwards;

pub fn main() !void {
    print("hello from main\n", .{});
    // const stdin = ;

    const allocator = std.heap.page_allocator;

    // Buffer for reading from stdin in chunks
    const inbuff = try allocator.alloc(u8, 128);
    defer allocator.free(inbuff);

    var inbuff2 = try allocator.alloc(u8, 128);
    var n: usize = 0;
    defer allocator.free(inbuff2);

    const max_idle = 10; // Max number of idle loops before deciding we have no more input
    var idle: u8 = max_idle;
    const loop_timeout = 1000 * std.time.ns_per_us; // 1ms
    var poller = std.io.poll(allocator, enum { stdin }, .{ .stdin = std.io.getStdIn() });
    while (true) {
        _ = idle > 0 or break;
        const fifo = poller.fifo(.stdin);
        const n_readable = fifo.readableLength();
        var n_read: usize = 0;
        if (n_readable > 0) {
            n_read = fifo.read(inbuff);
        } else {
            const keep_pooling = try poller.pollTimeout(loop_timeout);
            if (!keep_pooling) {
                break;
            }
        }
        if (n_read > 0) {
            while (n_read > inbuff2.len - n) { // Expand the buffer if needed
                const new_buff = try allocator.realloc(inbuff2, inbuff2.len + 128);
                inbuff2 = new_buff;
            }

            memcopy(u8, inbuff2[n..], inbuff[0..n_read]);
            n += n_read;
            print("Read {d} bytes. The total is now {d}\n", .{ n_read, n });
            // print("--------------------------------------------\n{s}\n--------------------------------------------\n", .{inbuff2});
            idle = max_idle; // We got some data! Reset the idle
        } else {
            idle -= 1;
            print("Idle\n", .{});
        }
    }

    // Trim the buffer to the actual size
    inbuff2 = try allocator.realloc(inbuff2, n);
    print("--------------------------------------------\n{s}\n--------------------------------------------\n", .{inbuff2});

    print("Read {d} bytes\n", .{n});

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
