const std = @import("std");
const Vec = @import("utils.zig").Vec;
const UnionFind = @import("utils.zig").UnionFind;
const topK = @import("utils.zig").topK;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    var points = std.ArrayList(Vec(3, i64)){};
    while (try reader.interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        try points.append(alloc, .{
            .coords = [_]i64{
                try std.fmt.parseInt(i64, it.next() orelse @panic("no x"), 10),
                try std.fmt.parseInt(i64, it.next() orelse @panic("no y"), 10),
                try std.fmt.parseInt(i64, it.next() orelse @panic("no z"), 10),
            },
        });
    }
    const n = points.items.len;

    const Edge = struct {
        const Self = @This();

        u: usize,
        v: usize,
        weight: i64,

        pub fn lessThan(_: void, a: Self, b: Self) bool {
            return a.weight < b.weight;
        }
    };

    var possible_edges = std.ArrayList(Edge){};
    for (0..n) |u| {
        for (u + 1..n) |v| {
            try possible_edges.append(alloc, .{ .u = u, .v = v, .weight = points.items[u].distSqr(points.items[v]) });
        }
    }
    std.mem.sort(Edge, possible_edges.items, {}, Edge.lessThan);

    var uf = try UnionFind.init(alloc, n);

    for (0..possible_edges.items.len) |i| {
        const e = possible_edges.items[i];
        _ = uf.unite(e.u, e.v);
        const inserted_edges = i + 1;

        if (inserted_edges == 10 or inserted_edges == 1000) {
            const component_sizes = topK(usize, 3, uf.size);
            const p = component_sizes[0] * component_sizes[1] * component_sizes[2];
            try writer.interface.print("product after {} edges: {}\n", .{ inserted_edges, p });
        }

        if (uf.size[uf.find(e.u)] == n) {
            const ux = points.items[e.u].x();
            const vx = points.items[e.v].x();
            try writer.interface.print("connected after {} edges\n", .{inserted_edges});
            try writer.interface.print("product of x coordinates {} and {}: {}\n", .{ ux, vx, ux * vx });
            break;
        }
    }

    try writer.interface.flush();
}
