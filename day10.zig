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

    pub fn joltageStepsNeeded(self: *const Self, filename: []const u8, alloc: std.mem.Allocator) !u64 {
        {
            var file = try std.fs.cwd().createFile(filename, .{});
            defer file.close();
            var buf: [1024]u8 = undefined;
            var writer = file.writer(&buf);

            try writer.interface.print("MINIMIZE\n", .{});

            try writer.interface.print("  obj: zero", .{});
            for (0..self.buttons.len) |i| try writer.interface.print(" + x{}", .{i});
            try writer.interface.print("\n", .{});

            try writer.interface.print("SUBJECT TO\n", .{});
            for (self.joltages, 0..) |jol, index| {
                try writer.interface.print("  c{}: zero", .{index});
                for (self.buttons, 0..) |button, b| {
                    if (std.mem.indexOfScalar(u5, button.indices, @intCast(index))) |_| {
                        try writer.interface.print(" + x{}", .{b});
                    }
                }
                try writer.interface.print(" = {}\n", .{jol});
            }

            try writer.interface.print("BOUNDS\n", .{});
            try writer.interface.print("  zero = 0\n", .{});

            try writer.interface.print("INTEGERS\n", .{});
            for (0..self.buttons.len) |i| try writer.interface.print("  x{}\n", .{i});

            try writer.interface.print("END\n", .{});

            try writer.interface.flush();
        }

        const output = try std.process.Child.run(.{
            .allocator = alloc,
            .argv = &.{ "scip", "-f", filename },
        });

        var lines = std.mem.splitScalar(u8, output.stdout, '\n');
        while (lines.next()) |line| {
            const marker = "objective value: ";
            if (std.mem.startsWith(u8, line, marker)) {
                const num_str = std.mem.trim(u8, line[marker.len..], " ");
                return std.fmt.parseUnsigned(u64, num_str, 10);
            }
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

    var machine_id: usize = 1;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        const m = try Machine.parse(alloc, line);
        s1 += try m.indicatorStepsNeeded(alloc);
        s2 += try m.joltageStepsNeeded(try std.fmt.allocPrint(alloc, "machine_{}.lp", .{machine_id}), alloc);
        machine_id += 1;
    }

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
