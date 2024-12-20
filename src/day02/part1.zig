const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const stdin = @import("stdin");

const utils = @import("utils.zig");

const ragged_slice = @import("ragged_slice");

pub fn parseReactors(alloc: std.mem.Allocator, in: []const u8) !ragged_slice.RaggedSlice(u8) {
    var lines_it = stdin.splitLines(in);
    var i: usize = 0;

    var reactors = try ragged_slice.RaggedSlice(u8).init(alloc);

    while (lines_it.next()) |line| : (i += 1) {
        var it = std.mem.tokenizeScalar(u8, line, ' ');

        var reactor = std.ArrayList(u8).init(alloc);
        while (it.next()) |token| {
            const level = try std.fmt.parseInt(u8, token, 10);
            try reactor.append(level);
        }
        try reactors.appendRow(try reactor.toOwnedSlice());
    }

    return reactors;
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    const reactors = try parseReactors(alloc, in);
    defer reactors.deinit();

    var n_safe: usize = 0;
    var rit = reactors.iterRows();
    while (rit.next()) |reactor| {
        const rt = utils.determineReactorType(reactor);
        if (rt == utils.reactor_type.Safe) {
            n_safe += 1;
        }
    }

    const answer = n_safe;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
