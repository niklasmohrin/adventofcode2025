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
