const std = @import("std");
const SBuffer = @import("sync_buffer.zig").TSBuffer;

pub fn main() !void {
    // // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!
    std.debug.print("\n>>> ImageStreamer\n\n", .{});

    std.debug.print("SyncBuffer test:\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var buffer = try SBuffer.init(gpa.allocator(), 640 * 480);
    defer buffer.deinit();

    var count: u8 = 0;
    while (count < 5) : (count += 1) {
        std.debug.print("Loop {d}:\n", .{count});

        for (0..3) |_| {
            if (buffer.acquire_producer_frame()) |frame| {
                produce_frame(frame);
                buffer.release_producer_frame();
            }
        }
        for (0..2) |_| {
            if (buffer.acquire_consumer_frame()) |frame| {
                consume_frame(frame);
                buffer.release_consumer_frame();
            }
        }
    }
}

fn produce_frame(frame: []u16) void {
    const static = struct {
        var frame_count: u16 = 0;
    };
    frame[0] = static.frame_count;
    static.frame_count += 1;
    std.debug.print(">>> Produced frame {d}\n", .{frame[0]});
}
fn consume_frame(frame: []u16) void {
    std.debug.print("--- Consumed frame {d}\n", .{frame[0]});
}

test "Placeholder" {
    try std.testing.expect(true);
}
