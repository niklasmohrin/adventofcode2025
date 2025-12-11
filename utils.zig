const std = @import("std");

pub fn splitOnce(comptime T: type, s: []const T, p: T) ?struct { []const T, []const T } {
    var it = std.mem.splitScalar(T, s, p);
    const first = it.next().?;
    const second = it.next().?;
    if (it.rest().len > 0) {
        return null;
    }
    return .{ first, second };
}

pub const Grid = struct {
    const Self = @This();

    data: []u8,
    width: usize,
    height: usize,

    pub fn init(data: []u8) Grid {
        const width = std.mem.indexOfScalar(u8, data, '\n') orelse @panic("no newline found");
        std.debug.assert(data.len % (width + 1) == 0);
        const height = data.len / (width + 1);
        return .{
            .data = data,
            .width = width,
            .height = height,
        };
    }

    pub fn index(self: *const Grid, x: usize, y: usize) usize {
        return y * (self.width + 1) + x;
    }

    pub fn get(self: *const Self, x: usize, y: usize) u8 {
        return self.data[self.index(x, y)];
    }
};

pub fn Vec(comptime d: usize, comptime T: type) type {
    return struct {
        const Self = @This();

        coords: [d]T,

        pub fn x(self: Self) T {
            return self.coords[0];
        }

        pub fn distSqr(self: Self, other: Self) T {
            var res: T = 0;
            for (0..d) |i| res += (self.coords[i] - other.coords[i]) * (self.coords[i] - other.coords[i]);
            return res;
        }
    };
}

pub const UnionFind = struct {
    const Self = @This();

    parent: []usize,
    size: []usize,

    pub fn init(gpa: std.mem.Allocator, n: usize) !Self {
        var parent = try gpa.alloc(usize, n);
        var size = try gpa.alloc(usize, n);
        for (0..n) |i| {
            parent[i] = i;
            size[i] = 1;
        }
        return .{ .parent = parent, .size = size };
    }

    pub fn find(self: *Self, key: usize) usize {
        var res = key;
        while (self.parent[res] != res) res = self.parent[res];
        var cur = key;
        while (self.parent[cur] != cur) {
            const next = self.parent[cur];
            self.parent[cur] = res;
            cur = next;
        }
        return res;
    }

    pub fn unite(self: *Self, k1: usize, k2: usize) bool {
        var r1 = self.find(k1);
        var r2 = self.find(k2);
        if (r1 == r2) return false;
        if (self.size[r1] < self.size[r2]) std.mem.swap(usize, &r1, &r2);
        self.parent[r2] = r1;
        self.size[r1] += self.size[r2];
        self.size[r2] = 0;
        return true;
    }
};

pub fn topK(comptime T: type, comptime k: usize, items: []T) [k]T {
    var buf: [k + 1]T = undefined;
    var sorted = std.ArrayList(T).initBuffer(&buf);
    outer: for (items) |item| {
        if (sorted.items.len == k + 1) _ = sorted.pop();
        for (0..sorted.items.len) |i| {
            if (sorted.items[i] < item) {
                sorted.insertAssumeCapacity(i, item);
                continue :outer;
            }
        }
        sorted.appendAssumeCapacity(item);
    }
    return buf[0..k].*;
}
