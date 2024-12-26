const std = @import("std");
// const testing = std.testing;
const print = std.debug.print;
const assert = std.debug.assert;
const stdin = @import("stdin");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const in = try stdin.readAllStdin(alloc);
    defer alloc.free(in);

    var scanner = Scanner.init(in, alloc);
    defer scanner.deinit();

    try scanner.scanTokens();

    var sum: u32 = 0;

    var stack: [6]Token = undefined;
    const want: [6]TokenKind = .{
        TokenKind.Mul,
        TokenKind.Lbrace,
        TokenKind.Number,
        TokenKind.Comma,
        TokenKind.Number,
        TokenKind.Rbrace,
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

    // 208085114

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{sum});
}

// Inspired by https://github.com/eikooc/lox-interpreter-zig/blob/main/src/scanner.zig#L188

const TokenKind = enum {
    Mul,
    Lbrace,
    Rbrace,
    Comma,
    Number,
    Other,
};

const Token = struct {
    tag: TokenKind,
    loc: struct {
        start: usize,
        end: usize,
    },
};

const Scanner = struct {
    const Self = @This();
    allocator: std.mem.Allocator,

    tokens: std.ArrayList(Token),
    current: usize = 0,

    source: []const u8,

    pub fn init(source: []const u8, allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .tokens = std.ArrayList(Token).init(allocator),
            .source = source,
        };
    }

    pub fn deinit(self: *Self) void {
        self.tokens.deinit();
    }

    fn isAtEnd(self: *Self) bool {
        return self.current >= self.source.len - 1;
    }

    pub fn scanTokens(self: *Self) !void {
        while (!isAtEnd(self)) {
            try scanToken(self);
        }

        try scanToken(self); // Scan the last token
    }

    pub fn scanToken(self: *Self) !void {
        const c = self.peek(); // current token

        switch (c) {
            '(' => {
                try self.appendToken(TokenKind.Lbrace, self.current, self.current + 1);
                self.current += 1;
            },
            ')' => {
                try self.appendToken(TokenKind.Rbrace, self.current, self.current + 1);
                self.current += 1;
            },
            ',' => {
                try self.appendToken(TokenKind.Comma, self.current, self.current + 1);
                self.current += 1;
            },
            '0'...'9' => {
                try number(self);
                self.current += 1;
            },
            'm' => {
                if (match(self, "mul")) {
                    try self.appendToken(TokenKind.Mul, self.current, self.current + 3);
                    self.current += 3;
                } else {
                    // This is an 'm' but it does not match 'mul'
                    try self.appendToken(TokenKind.Other, self.current, self.current + 1);
                    self.current += 1;
                }
            },
            else => {
                // some other character
                try self.appendToken(TokenKind.Other, self.current, self.current + 1);
                self.current += 1;
            },
        }

        return;
    }

    fn peek(self: *Self) u8 {
        return self.source[self.current];
    }

    fn number(self: *Self) !void {
        var i: usize = 0;
        while (true) {
            const c = self.peek();
            if (c < '0' or c > '9') {
                self.current -= 1;
                break;
            }
            self.current += 1;
            i += 1;
        }

        try self.appendToken(TokenKind.Number, self.current - i + 1, self.current + 1);
    }

    // Match the current token with the expected string. Do not advance the current pointer.
    fn match(self: *Self, expected: []const u8) bool {
        if (self.isAtEnd()) {
            return false;
        }
        if (std.mem.eql(u8, expected, self.source[self.current..(self.current + expected.len)])) {
            return true;
        }
        return false;
    }

    fn appendToken(
        self: *Self,
        tag: TokenKind,
        start: usize,
        end: usize,
    ) !void {
        try self.tokens.append(Token{
            .tag = tag,
            .loc = .{
                .start = start,
                .end = end,
            },
        });
    }
};
