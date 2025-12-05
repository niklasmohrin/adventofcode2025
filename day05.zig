const std = @import("std");
const splitOnce = @import("utils.zig").splitOnce;

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

    const Event = struct {
        time: u64,
        kind: enum {
            start,
            end,
            query,
        },

        pub fn lessThan(_: void, a: @This(), b: @This()) bool {
            return a.time < b.time or a.time == b.time and @intFromEnum(a.kind) < @intFromEnum(b.kind);
        }
    };

    var events = std.ArrayList(Event){};
    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;

        const start_str, const end_str = splitOnce(u8, line, '-') orelse @panic("wrong line");
        try events.append(alloc, .{ .time = try std.fmt.parseInt(u64, start_str, 10), .kind = .start });
        try events.append(alloc, .{ .time = try std.fmt.parseInt(u64, end_str, 10) + 1, .kind = .end });
    }
    while (try reader.interface.takeDelimiter('\n')) |line| {
        try events.append(alloc, .{ .time = try std.fmt.parseInt(u64, line, 10), .kind = .query });
    }

    std.mem.sortUnstable(Event, events.items, {}, Event.lessThan);

    var active: u32 = 0;
    var start: u64 = 0;
    for (events.items) |event| {
        switch (event.kind) {
            .start => {
                active += 1;
                if (active == 1) start = event.time;
            },
            .end => {
                active -= 1;
                if (active == 0) s2 += event.time - start;
            },
            .query => s1 += @intFromBool(active > 0),
        }
    }

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
