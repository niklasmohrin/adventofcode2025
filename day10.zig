const std = @import("std");

const Machine = struct {
    const Self = @This();

    const Button = struct {
        indices: []u5,
        mask: u32,
    };
    const ParseError = error{
        Eos,
    };

    indicators: u32,
    buttons: []Button,
    joltages: []u32,

    pub fn parse(alloc: std.mem.Allocator, s: []const u8) !Self {
        var it = std.mem.splitScalar(u8, s, ' ');

        const indicators_str = it.next() orelse return ParseError.Eos;
        var indicators: u32 = 0;
        for (0..indicators_str.len - 2) |i| {
            indicators <<= 1;
            indicators |= @intFromBool(indicators_str[indicators_str.len - 2 - i] == '#');
        }

        var buttons = std.ArrayList(Button){};
        var joltages = std.ArrayList(u32){};

        while (it.next()) |t| {
            var iit = std.mem.splitScalar(u8, t[1 .. t.len - 1], ',');
            if (t[0] == '{') {
                while (iit.next()) |j| try joltages.append(alloc, try std.fmt.parseUnsigned(u32, j, 10));
                continue;
            }
            var button_indices = std.ArrayList(u5){};
            var mask: u32 = 0;
            while (iit.next()) |bs| {
                const b = try std.fmt.parseUnsigned(u5, bs, 10);
                mask |= @as(u32, 1) << (b);
                try button_indices.append(alloc, b);
            }
            try buttons.append(alloc, .{ .indices = button_indices.items, .mask = mask });
        }

        return .{ .indicators = indicators, .buttons = buttons.items, .joltages = joltages.items };
    }

    pub fn indicatorStepsNeeded(self: *const Self, alloc: std.mem.Allocator) !u64 {
        var dist = std.AutoHashMap(u32, usize).init(alloc);
        try dist.put(0, 0);

        var q = std.array_list.Managed(u32).init(alloc);
        try q.append(0);
        var q_index: usize = 0;

        while (q_index < q.items.len) {
            const u = q.items[q_index];
            q_index += 1;

            if (u == self.indicators) return dist.get(u) orelse @panic("no dist known");

            for (self.buttons) |b| {
                const v = u ^ b.mask;
                if (dist.contains(v)) continue;
                try dist.put(v, 1 + (dist.get(u) orelse @panic("no dist known")));
                try q.append(v);
            }
        }

        @panic("indicator not reachable");
    }

    pub fn joltageStepsNeededFixedDimensions(self: *const Self, comptime d: usize, alloc: std.mem.Allocator) !u64 {
        var dist = std.AutoHashMap([d]u32, usize).init(alloc);
        try dist.put(std.mem.zeroes([d]u32), 0);

        var q = std.array_list.Managed([d]u32).init(alloc);
        try q.append(std.mem.zeroes([d]u32));
        var q_index: usize = 0;

        while (q_index < q.items.len) {
            const u = q.items[q_index];
            q_index += 1;

            if (std.mem.eql(u32, &u, self.joltages)) return dist.get(u) orelse @panic("no dist known");

            outer: for (self.buttons) |button| {
                var v = u;
                for (button.indices) |i| v[i] += 1;
                for (0..u.len) |i| if (v[i] > self.joltages[i]) continue :outer;
                if (dist.contains(v)) continue;
                try dist.put(v, 1 + (dist.get(u) orelse @panic("no dist known")));
                try q.append(v);
            }
        }

        @panic("joltage requirements not reachable");
    }

    pub fn joltageStepsNeeded(self: *const Self, alloc: std.mem.Allocator) !u64 {
        inline for (1..15) |d| {
            if (self.joltages.len == d) return self.joltageStepsNeededFixedDimensions(d, alloc);
        }
        unreachable;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    var s1: u64 = 0;
    var s2: u64 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const m = try Machine.parse(alloc, line);
        std.debug.print("{}\n", .{m});
        s1 += try m.indicatorStepsNeeded(alloc);
        s2 += try m.joltageStepsNeeded(alloc);
    }

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
