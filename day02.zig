const std = @import("std");
const splitOnce = @import("utils.zig").splitOnce;

fn is_invalid(x: u64) bool {
    const digits = std.math.log10_int(x) + 1;
    if (@mod(digits, 2) == 1) return false;
    const m = std.math.pow(u64, 10, digits / 2);
    const front = x / m;
    const back = x % m;
    return front == back;
}

fn is_invalid2(x: u64) bool {
    const digits = std.math.log10_int(x) + 1;
    for (1..(digits / 2 + 1)) |pattern_length| {
        const m = std.math.pow(u64, 10, pattern_length);
        if (digits % pattern_length != 0) continue;
        var remaining = x;
        while (remaining > 0) : (remaining /= m) {
            if (remaining % m != x % m) break;
        } else return true;
    }
    return false;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    const input = try reader.interface.allocRemaining(alloc, .unlimited);

    var it = std.mem.splitScalar(u8, input, ',');
    var s1: u64 = 0;
    var s2: u64 = 0;
    while (it.next()) |range_str| {
        const start_str, const end_str = splitOnce(u8, std.mem.trim(u8, range_str, " \n"), '-').?;
        // std.debug.print("{s} -> {s} and {s}\n", .{ range_str, start_str, end_str });
        const start = try std.fmt.parseUnsigned(u64, start_str, 10);
        const end = try std.fmt.parseUnsigned(u64, end_str, 10);
        for (start..end + 1) |x| {
            if (is_invalid(x)) {
                s1 += x;
                // std.debug.print("invalid {}\n", .{x});
            }
            if (is_invalid2(x)) {
                s2 += x;
                // std.debug.print("invalid2 {}\n", .{x});
            }
        }
    }

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
