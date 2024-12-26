const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const assert = std.debug.assert;
const stdin = @import("stdin");

const utils = @import("utils.zig");

fn Pattern(comptime N: u8) type {
    return struct {
        const Self = @This();

        want: [N]utils.TokenKind,
        stack: [N]utils.Token = undefined,
        i: usize = 0,

        pub fn reset(self: *Self) void {
            self.i = 0;
            self.stack = undefined;
        }

        pub fn push(self: *Self, token: utils.Token) void {
            self.stack[self.i] = token;
            self.i += 1;
        }

        pub fn current(self: *Self) utils.TokenKind {
            return self.want[self.i];
        }

        pub fn atEnd(self: *Self) bool {
            return self.i == N;
        }
    };
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    var scanner = utils.Scanner.init(in, alloc);
    defer scanner.deinit();

    try scanner.scanTokens();

    var sum: u32 = 0;

    var mul: Pattern(6) = .{ .want = .{
        utils.TokenKind.Mul,
        utils.TokenKind.Lbrace,
        utils.TokenKind.Number,
        utils.TokenKind.Comma,
        utils.TokenKind.Number,
        utils.TokenKind.Rbrace,
    } };

    for (scanner.tokens.items) |token| {
        if (token.tag == mul.current()) {
            mul.push(token);
            // push the token to the stack
        } else {
            // clear the stack
            mul.reset();
        }

        if (mul.atEnd()) {
            // Evaluate the expression
            print("Evaluating expression: {s}\n", .{in[mul.stack[0].loc.start..mul.stack[mul.stack.len - 1].loc.end]});
            const a = try std.fmt.parseInt(u32, in[mul.stack[2].loc.start..mul.stack[2].loc.end], 10);
            const b = try std.fmt.parseInt(u32, in[mul.stack[4].loc.start..mul.stack[4].loc.end], 10);

            const result = a * b;
            // print("{d} = {d} * {d}\n", .{ result, a, b });
            sum += result;

            // Reset the stack
            mul.reset();
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{sum});
}
