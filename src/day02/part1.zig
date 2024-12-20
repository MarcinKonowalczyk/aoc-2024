const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const stdin = @import("stdin");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    var lines_it = stdin.splitLines(in);
    var i: usize = 0;

    var reactors = std.ArrayList([]u8).init(alloc);
    defer {
        // Free all the elements before freeing the array
        for (reactors.items) |reactor| {
            alloc.free(reactor);
        }
        alloc.free(reactors.items);
    }

    while (lines_it.next()) |line| : (i += 1) {
        var it = std.mem.tokenizeScalar(u8, line, ' ');

        var reactor = std.ArrayList(u8).init(alloc);
        while (it.next()) |token| {
            const level = try std.fmt.parseInt(u8, token, 10);
            try reactor.append(level);
        }
        try reactors.append(try reactor.toOwnedSlice());
    }

    var n_safe: usize = 0;
    for (reactors.items) |reactor| {
        const rt = determineReactorType(reactor);
        if (rt == reactor_type.Safe) {
            n_safe += 1;
        }
    }

    const answer = n_safe;

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{answer});
}

const reactor_type = enum {
    Safe,
    Unsafe,
};

fn determineReactorType(reactor: []u8) reactor_type {
    var last = reactor[0];
    var sign: i2 = 0;
    const delta_type = i9;

    const min_delta = 1;
    const max_delta = 3;

    for (reactor[1..], 0..) |level, i| {
        const delta: delta_type = @as(delta_type, level) - @as(delta_type, last);
        last = level;

        if (i == 0) {
            sign = toSign(delta);
        } else {
            if (toSign(delta) != sign) {
                return reactor_type.Unsafe;
            }
        }

        const abs_delta = @abs(delta);

        if (abs_delta < min_delta or abs_delta > max_delta) {
            return reactor_type.Unsafe;
        }
    }
    return reactor_type.Safe;
}

inline fn toSign(x: anytype) i2 {
    if (x > 0) {
        return 1;
    } else if (x < 0) {
        return -1;
    } else {
        return 0;
    }
}
