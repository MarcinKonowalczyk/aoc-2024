const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

// Inspired by https://github.com/eikooc/lox-interpreter-zig/blob/main/src/scanner.zig#L188

pub const TokenKind = enum {
    Lbrace,
    Rbrace,
    Comma,
    Number,
    Other,
    Mul,
    Do,
    Dont,
};

pub const Token = struct {
    tag: TokenKind,
    loc: struct {
        start: usize,
        end: usize,
    },
};

pub const Scanner = struct {
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
            'd' => {
                if (match(self, "don't")) {
                    try self.appendToken(TokenKind.Dont, self.current, self.current + 4);
                    self.current += 5;
                } else if (match(self, "do")) {
                    try self.appendToken(TokenKind.Do, self.current, self.current + 2);
                    self.current += 2;
                } else {
                    // This is a 'd' but it does not match 'do' or 'dont'
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
