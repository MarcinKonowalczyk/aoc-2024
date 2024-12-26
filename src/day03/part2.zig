const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const assert = std.debug.assert;
const stdin = @import("stdin");

const utils = @import("utils.zig");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    var scanner = utils.Scanner.init(in, alloc);
    defer scanner.deinit();

    try scanner.scanTokens();

    var sum: u32 = 0;

    var stack: [6]utils.Token = undefined;
    const want: [6]utils.TokenKind = .{
        utils.TokenKind.Mul,
        utils.TokenKind.Lbrace,
        utils.TokenKind.Number,
        utils.TokenKind.Comma,
        utils.TokenKind.Number,
        utils.TokenKind.Rbrace,
    };
    var i: usize = 0;
    for (scanner.tokens.items) |token| {
        if (token.tag == want[i]) {
            // push the token to the stack
            stack[i] = token;
            i += 1;
        } else {
            // clear the stack
            i = 0;
            stack[i] = token;
        }

        if (i == 6) {
            // Evaluate the expression
            print("Evaluating expression: {s}\n", .{in[stack[0].loc.start..stack[stack.len - 1].loc.end]});
            const a = try std.fmt.parseInt(u32, in[stack[2].loc.start..stack[2].loc.end], 10);
            const b = try std.fmt.parseInt(u32, in[stack[4].loc.start..stack[4].loc.end], 10);

            const result = a * b;
            // print("{d} = {d} * {d}\n", .{ result, a, b });
            sum += result;

            // Reset the stack
            i = 0;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{sum});
}
