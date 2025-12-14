const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    const V = [3]u8;
    var id = std.AutoHashMap(V, usize).init(alloc);
    var g = std.ArrayList(std.ArrayList(usize)){};

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const u = line[0..3].*;
        const vs = line[5..];

        const ue = try id.getOrPut(u);
        if (!ue.found_existing) {
            ue.value_ptr.* = g.items.len;
            try g.append(alloc, .{});
        }
        const ui = ue.value_ptr.*;

        for (0..(vs.len + 1) / 4) |i| {
            const v = vs[4 * i ..][0..3].*;
            const ve = try id.getOrPut(v);
            if (!ve.found_existing) {
                ve.value_ptr.* = g.items.len;
                try g.append(alloc, .{});
            }

            try g.items[ui].append(alloc, ve.value_ptr.*);
        }
    }

    const Dfs = struct {
        const Self = @This();
        const UNVIS: u64 = std.math.maxInt(u64);
        dp: []u64,
        g: []const std.ArrayList(usize),

        pub fn init(gpa: std.mem.Allocator, graph: []const std.ArrayList(usize)) !Self {
            return .{ .dp = try gpa.alloc(u64, graph.len), .g = graph };
        }

        pub fn run(self: *Self, start: usize, end: usize) u64 {
            @memset(self.dp, UNVIS);
            self.dp[end] = 1;
            self.visit(start, start);
            return self.dp[start];
        }
        fn visit(self: *Self, u: usize, p: usize) void {
            self.dp[u] = 0;
            for (self.g[u].items) |v| {
                if (v == p) continue;
                if (self.dp[v] == UNVIS) self.visit(v, u);
                self.dp[u] += self.dp[v];
            }
        }
    };

    var dfs = try Dfs.init(alloc, g.items);

    const you = id.get("you".*) orelse @panic("no you");
    const out = id.get("out".*) orelse @panic("no out");
    const svr = id.get("svr".*) orelse @panic("no svr");
    const dac = id.get("dac".*) orelse @panic("no dac");
    const fft = id.get("fft".*) orelse @panic("no fft");

    const s1 = dfs.run(you, out);
    const paths_dac_fft = dfs.run(svr, dac) * dfs.run(dac, fft) * dfs.run(fft, out);
    const paths_fft_dac = dfs.run(svr, fft) * dfs.run(fft, dac) * dfs.run(dac, out);
    const s2 = paths_dac_fft + paths_fft_dac; // it's a DAG, so one of them is zero and the other is the number we want

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
