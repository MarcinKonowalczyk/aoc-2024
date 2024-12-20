const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;

const utils = @import("utils.zig");

const stdin = @import("stdin");
const ragged_slice = @import("ragged_slice");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    const reactors = try utils.parseReactors(alloc, in);
    defer reactors.deinit();

    var n_safe: usize = 0;
    var it = reactors.iterRows();
    while (it.next()) |reactor| {
        const rt = utils.determineReactorType(reactor);
        if (rt == utils.reactor_type.Safe) {
            n_safe += 1;
        }
    }

    const answer = n_safe;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
