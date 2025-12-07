const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    const input = try reader.interface.allocRemaining(alloc, .unlimited);

    var s1: u64 = 0;
    var s2: u64 = 0;

    var it = std.mem.splitScalar(u8, input, '\n');
    var lines = std.ArrayList([]const u8){};
    while (it.next()) |line| {
        if (line.len == 0) break;
        try lines.append(alloc, line);
    }

    const operators = lines.pop() orelse @panic("no lines");

    var start: usize = 0;
    var buf = std.ArrayList(u8){};
    try buf.resize(alloc, lines.items.len);

    while (start < operators.len) {
        const end = std.mem.indexOfAnyPos(u8, operators, start + 1, "+*") orelse operators.len;
        defer start = end;

        var row_result: u64 = switch (operators[start]) {
            '+' => 0,
            '*' => 1,
            else => unreachable,
        };
        var col_result = row_result;

        for (lines.items) |line| {
            const num = try std.fmt.parseUnsigned(u64, std.mem.trim(u8, line[start..end], " "), 10);
            switch (operators[start]) {
                '+' => row_result += num,
                '*' => row_result *= num,
                else => unreachable,
            }
        }
        s1 += row_result;

        for (start..end) |x| {
            for (0..buf.items.len) |y| {
                buf.items[y] = lines.items[y][x];
            }

            const num_str = std.mem.trim(u8, buf.items, " ");
            if (num_str.len == 0) continue;
            const num = try std.fmt.parseUnsigned(u64, num_str, 10);
            switch (operators[start]) {
                '+' => col_result += num,
                '*' => col_result *= num,
                else => unreachable,
            }
        }

        s2 += col_result;
    }

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
