const std = @import("std");
const Allocator = std.mem.Allocator;

pub const TSBuffer = struct {
    const FrameState = enum { FREE, PRODUCING, PRODUCED, CONSUMING };
    const Entry = struct { state: FrameState, value: []u16 };

    entries: [3]Entry,
    access: std.Thread.Mutex,
    alloc: Allocator,

    pub fn init(allocator: Allocator, pixels: usize) !@This() {
        const frame1 = try allocator.alloc(u16, pixels);
        errdefer allocator.free(frame1);
        const frame2 = try allocator.alloc(u16, pixels);
        errdefer allocator.free(frame2);
        const frame3 = try allocator.alloc(u16, pixels);
        errdefer allocator.free(frame3);

        return .{ .entries = [3]Entry{ Entry{ .state = .FREE, .value = frame1 }, Entry{ .state = .FREE, .value = frame2 }, Entry{ .state = .FREE, .value = frame3 } }, .access = std.Thread.Mutex{}, .alloc = allocator };
    }

    pub fn deinit(self: *@This()) void {
        for (&self.entries) |*entry| {
            self.alloc.free(entry.value);
        }
    }

    fn find_entry(self: *@This(), state: FrameState) ?*Entry {
        for (&self.entries) |*entry| {
            if (entry.state == state) return entry;
        }
        return null;
    }

    pub fn acquire_producer_frame(self: *@This()) ?*[]u16 { // producer_frame
        self.access.lock();
        defer self.access.unlock();

        if (self.find_entry(.FREE)) |entry| {
            entry.state = .PRODUCING;
            return &entry.value;
        }
        return null;
    }
    pub fn release_producer_frame(self: *@This()) void {
        self.access.lock();
        defer self.access.unlock();

        if (self.find_entry(.PRODUCING)) |entry| {
            if (self.find_entry(.PRODUCED)) |entry_prev| entry_prev.state = .FREE;
            entry.state = .PRODUCED;
        }
    }

    pub fn acquire_consumer_frame(self: *@This()) ?*[]u16 { // consumer_frame
        self.access.lock();
        defer self.access.unlock();

        if (self.find_entry(.PRODUCED)) |entry| {
            entry.state = .CONSUMING;
            return &entry.value;
        }
        return null;
    }
    pub fn release_consumer_frame(self: *@This()) void {
        self.access.lock();
        defer self.access.unlock();

        if (self.find_entry(.CONSUMING)) |entry| entry.state = .FREE;
    }
};

test "TSBuffer (de)initializion" {
    var buffer = try TSBuffer.init(std.testing.allocator, 1024);
    defer buffer.deinit();

    try std.testing.expect(false);
}

// FIXME: further testing
