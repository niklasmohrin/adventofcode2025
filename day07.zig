const std = @import("std");
const Grid = @import("utils.zig").Grid;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    const input = try reader.interface.allocRemaining(alloc, .unlimited);
    const grid = Grid.init(input);

    var s1: u64 = 0;

    var active = std.AutoHashMap(usize, u64).init(alloc);
    for (0..grid.height) |y| {
        for (0..grid.width) |x| {
            switch (grid.get(x, y)) {
                'S' => try active.put(x, 1),
                '^' => {
                    if (active.fetchRemove(x)) |e| {
                        try active.put(x - 1, (active.get(x - 1) orelse 0) + e.value);
                        try active.put(x + 1, (active.get(x + 1) orelse 0) + e.value);
                        s1 += 1;
                    }
                },
                '.' => {},
                else => unreachable,
            }
        }
    }

    var s2: u64 = 0;
    var it = active.valueIterator();
    while (it.next()) |c| s2 += c.*;

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
