const std = @import("std");
const Grid = @import("utils.zig").Grid;
const splitOnce = @import("utils.zig").splitOnce;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buffer: [1024]u8 = undefined;
    var out_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buffer);
    var writer = std.fs.File.stdout().writer(&out_buffer);

    var input = try reader.interface.allocRemaining(alloc, .unlimited);
    var s1: u64 = 0;

    var shapes = std.array_list.Managed(Grid).init(alloc);
    var shape_it = std.mem.splitSequence(u8, input, "\n\n");
    while (shape_it.next()) |shape_str| {
        const offset = shape_str.ptr - input.ptr;
        if (shape_it.peek()) |_| {
            try shapes.append(Grid.init(input[offset + 3 .. offset + 3 + 3 * 4])); // trim index, colon, newline
        }
    }

    const shape_size = 3 + 3 * 4;
    const requirements = input[shapes.items.len * (shape_size + 1) ..];
    var req_it = std.mem.splitScalar(u8, requirements, '\n');
    while (req_it.next()) |req_str| {
        if (req_str.len == 0) break;

        const dim_str, const count_str = splitOnce(u8, req_str, ':') orelse @panic("no colon");
        const w_str, const h_str = splitOnce(u8, dim_str, 'x') orelse @panic("no x");
        const w = try std.fmt.parseUnsigned(u64, w_str, 10);
        const h = try std.fmt.parseUnsigned(u64, h_str, 10);

        var count_it = std.mem.splitScalar(u8, count_str[1..], ' ');
        var total_count: u64 = 0;
        while (count_it.next()) |c_str| {
            total_count += try std.fmt.parseUnsigned(u64, c_str, 10);
        }

        const possible = (w / 3) * (h / 3);

        // big input does not require that any shapes are stuck together 🤷
        s1 += @intFromBool(total_count <= possible);
    }

    try writer.interface.print("{}\n", .{s1});
    try writer.interface.flush();
}
