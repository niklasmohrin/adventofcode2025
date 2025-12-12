const std = @import("std");
const Vec = @import("utils.zig").Vec;
const Range = @import("utils.zig").Range;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    const P = Vec(2, i64);
    const down: P = comptime try .parse("0,1");
    const right: P = comptime try .parse("1,0");

    const Rect = struct {
        const Self = @This();

        x: Range(i64),
        y: Range(i64),

        pub fn init(c1: P, c2: P) Self {
            return .{
                .x = Range(i64).init(@min(c1.x(), c2.x()), @max(c1.x(), c2.x()) + 1),
                .y = Range(i64).init(@min(c1.y(), c2.y()), @max(c1.y(), c2.y()) + 1),
            };
        }

        pub fn contains(self: Self, p: P) bool {
            return self.x.contains(p.x()) and self.y.contains(p.y());
        }

        pub fn area(self: Self) u64 {
            return self.x.size() * self.y.size();
        }
    };

    var points = std.ArrayList(Vec(2, i64)){};
    var rects = std.ArrayList(Rect){};
    var min_y: i64 = std.math.maxInt(i64);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const p = try Vec(2, i64).parse(line);
        for (points.items) |q| {
            try rects.append(alloc, .init(p, q));
        }
        try points.append(alloc, p);
        min_y = @min(min_y, p.y());
    }

    var s1: u64 = 0;
    for (rects.items) |rect| s1 = @max(s1, rect.area());

    var min_by_y = std.AutoHashMap(i64, i64).init(alloc);
    var max_by_y = std.AutoHashMap(i64, i64).init(alloc);

    for (0..points.items.len) |i| {
        var p = points.items[i];
        var q = points.items[(i + 1) % points.items.len];
        const dd: usize = if (p.x() == q.x()) 1 else 0;
        if (p.coords[dd] > q.coords[dd]) std.mem.swap(P, &p, &q);
        const d: P = if (dd == 0) right else down;

        try min_by_y.put(p.y(), @min(p.x(), min_by_y.get(p.y()) orelse p.x()));
        try max_by_y.put(p.y(), @max(p.x(), max_by_y.get(p.y()) orelse p.x()));

        while (!std.meta.eql(p, q)) {
            p = p.add(d);
            try min_by_y.put(p.y(), @min(p.x(), min_by_y.get(p.y()) orelse p.x()));
            try max_by_y.put(p.y(), @max(p.x(), max_by_y.get(p.y()) orelse p.x()));
        }
    }

    var s2: u64 = 0;
    outer: for (rects.items) |rect| {
        var it = min_by_y.keyIterator();
        while (it.next()) |yp| {
            const y = yp.*;
            if (rect.y.contains(y)) {
                const green_range = Range(i64).init(min_by_y.get(y) orelse @panic("no min"), (max_by_y.get(y) orelse @panic("no max")) + 1);
                if (!rect.x.isSubset(green_range)) {
                    continue :outer;
                }
            }
        }

        s2 = @max(s2, rect.area());
    }

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
