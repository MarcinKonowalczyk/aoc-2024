const std = @import("std");
const print = std.debug.print;
const builtin = @import("builtin");
const testing = std.testing;
const process = std.process;
const fs = std.fs;
const ChildProcess = std.process.Child;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    var args = std.ArrayList([]const u8).init(alloc);
    defer args.deinit();

    try args.appendSlice(&[_][]const u8{ "ls", "-lha", "." });

    const res_stdout = try exec(alloc, args.items);
    try stdout.print("{s}\n", .{res_stdout});
}

fn exec(allocator: std.mem.Allocator, argv: []const []const u8) ![]u8 {
    const max_output_size = 100 * 1024 * 1024;
    var child_process = ChildProcess.init(argv, allocator);

    child_process.stdout_behavior = .Pipe;
    try child_process.spawn();

    const bytes = try child_process.stdout.?.reader().readAllAlloc(allocator, max_output_size);
    errdefer allocator.free(bytes);

    const term = try child_process.wait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                return error.CommandFailed;
            }
        },
        else => return error.CommandFailed,
    }
    return bytes;
}
