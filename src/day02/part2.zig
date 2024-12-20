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
            // Safe reactors remain safe
            n_safe += 1;
        } else {
            // print("trying to fix reactor: {any}\n", .{reactor});
            // See if we can fix the reactor by removing one element
            // This is not very performant since we're making a new alloc and a copy per
            // element, but its fine for now. Would be better to make a version of
            // `determineReactorType` that takes a slice and an index to skip. -MK

            remove_on_by_one: for (0..reactor.len) |i| {
                const new_reactor = try alloc.alloc(u8, reactor.len - 1);
                defer alloc.free(new_reactor);
                for (0..i) |j| {
                    new_reactor[j] = reactor[j];
                }
                for (i + 1..reactor.len) |j| {
                    new_reactor[j - 1] = reactor[j];
                }

                if (utils.determineReactorType(new_reactor) == utils.reactor_type.Safe) {
                    n_safe += 1;
                    break :remove_on_by_one;
                }
            }
        }
    }

    const answer = n_safe;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}
