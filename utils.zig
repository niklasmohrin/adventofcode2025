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
