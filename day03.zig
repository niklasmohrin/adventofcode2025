const std = @import("std");

fn part1(line: []const u8) !u64 {
    var best: u64 = 0;
    var max_right: u64 = try std.fmt.parseUnsigned(u64, line[0..1], 10);
    for (1..line.len) |i| {
        const digit: u64 = try std.fmt.parseUnsigned(u64, line[i .. i + 1], 10);
        best = @max(best, 10 * digit + max_right);
        max_right = @max(max_right, digit);
    }
    return best;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    const max_digits: usize = 12;

    var s1: u64 = 0;
    var s2: u64 = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        std.mem.reverse(u8, line);

        var dp = try alloc.alloc([max_digits + 1]u64, line.len);
        defer alloc.free(dp);
        @memset(dp, std.mem.zeroes([max_digits + 1]u64));
        dp[0][1] = try std.fmt.parseUnsigned(u64, line[0..1], 10);

        for (1..line.len) |prefix| {
            var new_digit: u64 = try std.fmt.parseUnsigned(u64, line[prefix .. prefix + 1], 10);
            for (1..@min(max_digits, prefix + 1) + 1) |digits| {
                dp[prefix][digits] = @max(new_digit + dp[prefix - 1][digits - 1], dp[prefix - 1][digits]);
                new_digit *= 10;
            }
        }

        std.debug.assert(try part1(line) == dp[line.len - 1][2]);
        std.debug.print("{s} -> {}\n", .{ line, dp[line.len - 1][max_digits] });

        s1 += dp[line.len - 1][2];
        s2 += dp[line.len - 1][max_digits];
    }

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
