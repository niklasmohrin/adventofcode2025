const std = @import("std");

pub fn main() !void {
    var out_buffer: [1024]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&out_buffer);

    const stdin = std.fs.File.stdin();
    var buffer: [1024]u8 = undefined;
    var reader = stdin.reader(&buffer);

    var pos: i32 = 50;
    var direct_zero_count: u32 = 0;
    var all_zero_count: u32 = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        const sign: i32 = switch (line[0]) {
            'L' => -1,
            'R' => 1,
            else => unreachable,
        };
        const offset = try std.fmt.parseInt(i32, line[1..], 10);
        var new_pos = pos + sign * offset;

        all_zero_count += @abs(@divFloor(new_pos, 100) - @divFloor(pos, 100));
        new_pos = @mod(new_pos, 100);
        direct_zero_count += @intFromBool(new_pos == 0);

        if (line[0] == 'L') {
            all_zero_count -= @intFromBool(pos == 0);
            all_zero_count += @intFromBool(new_pos == 0);
        }

        pos = new_pos;
        std.debug.print("{}\n", .{pos});
    }

    try stdout.interface.print("{} {}\n", .{ direct_zero_count, all_zero_count });
    try stdout.interface.flush();
}
