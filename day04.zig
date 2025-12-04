const std = @import("std");

const Grid = struct {
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

    pub fn blocked(self: *const Grid, x: usize, y: usize) bool {
        return self.data[y * (self.width + 1) + x] == '@';
    }
    pub fn remove(self: *Grid, x: usize, y: usize) void {
        self.data[y * (self.width + 1) + x] = 'x';
    }

    pub fn canAccess(self: *const Grid, x: usize, y: usize) bool {
        var neighboring: u8 = 0;
        neighboring += @intFromBool(0 < x and 0 < y and self.blocked(x - 1, y - 1));
        neighboring += @intFromBool(0 < x and self.blocked(x - 1, y));
        neighboring += @intFromBool(0 < x and y + 1 < self.height and self.blocked(x - 1, y + 1));
        neighboring += @intFromBool(0 < y and self.blocked(x, y - 1));
        neighboring += @intFromBool(y + 1 < self.height and self.blocked(x, y + 1));
        neighboring += @intFromBool(x + 1 < self.width and 0 < y and self.blocked(x + 1, y - 1));
        neighboring += @intFromBool(x + 1 < self.width and self.blocked(x + 1, y));
        neighboring += @intFromBool(x + 1 < self.width and y + 1 < self.height and self.blocked(x + 1, y + 1));
        return neighboring < 4;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    var grid = Grid.init(try reader.interface.allocRemaining(alloc, .unlimited));

    var s1: u32 = 0;
    for (0..grid.height) |y| {
        for (0..grid.width) |x| {
            s1 += @intFromBool(grid.blocked(x, y) and grid.canAccess(x, y));
        }
    }

    var s2: u32 = 0;
    var progress = true;
    while (progress) {
        progress = false;
        for (0..grid.height) |y| {
            for (0..grid.width) |x| {
                if (grid.blocked(x, y) and grid.canAccess(x, y)) {
                    s2 += 1;
                    progress = true;
                    grid.remove(x, y);
                }
            }
        }
    }

    try writer.interface.print("{} {}\n", .{ s1, s2 });
    try writer.interface.flush();
}
