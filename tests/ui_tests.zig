const std = @import("std");
const testing = std.testing;

// Mock text color for terminal output
const TextColor = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,
    
    pub fn ansiCode(self: TextColor) []const u8 {
        return switch (self) {
            .black => "30",
            .red => "31",
            .green => "32",
            .yellow => "33",
            .blue => "34",
            .magenta => "35",
            .cyan => "36",
            .white => "37",
            .bright_black => "90",
            .bright_red => "91",
            .bright_green => "92",
            .bright_yellow => "93",
            .bright_blue => "94",
            .bright_magenta => "95",
            .bright_cyan => "96",
            .bright_white => "97",
        };
    }
};

// Mock text style for terminal output
const TextStyle = enum {
    normal,
    bold,
    italic,
    underline,
    
    pub fn ansiCode(self: TextStyle) []const u8 {
        return switch (self) {
            .normal => "0",
            .bold => "1",
            .italic => "3",
            .underline => "4",
        };
    }
};

// Mock buffer to capture stdout output
const MockWriter = struct {
    buffer: std.ArrayList(u8),
    
    pub fn write(self: *MockWriter, bytes: []const u8) !usize {
        try self.buffer.appendSlice(bytes);
        return bytes.len;
    }
    
    pub fn writer(self: *MockWriter) std.ArrayList(u8).Writer {
        return self.buffer.writer();
    }
};

// Mock terminal UI component for testing
const TerminalUI = struct {
    stdout: std.ArrayList(u8).Writer,
    
    // Print a message with color and style
    pub fn print(self: *TerminalUI, msg: []const u8, color: TextColor, style: TextStyle) !void {
        try self.stdout.print("\x1b[{s};{s}m{s}\x1b[0m", .{style.ansiCode(), color.ansiCode(), msg});
    }
    
    // Print a message with color and style, followed by a newline
    pub fn println(self: *TerminalUI, msg: []const u8, color: TextColor, style: TextStyle) !void {
        try self.print(msg, color, style);
        try self.stdout.print("\n", .{});
    }
    
    // Draw a horizontal line
    pub fn drawHorizontalLine(self: *TerminalUI, width: usize, char: u8, color: TextColor) !void {
        try self.stdout.print("\x1b[{s}m", .{color.ansiCode()});
        
        var i: usize = 0;
        while (i < width) : (i += 1) {
            try self.stdout.writeByte(char);
        }
        
        try self.stdout.print("\x1b[0m\n", .{});
    }
    
    // Draw a title banner
    pub fn drawTitle(self: *TerminalUI, title: []const u8) !void {
        const padding = 4;
        const total_width = title.len + (padding * 2);
        
        try self.drawHorizontalLine(total_width, '=', .bright_yellow);
        try self.stdout.print("\x1b[{s}m", .{TextColor.bright_yellow.ansiCode()});
        
        // Print padding
        var i: usize = 0;
        while (i < padding) : (i += 1) {
            try self.stdout.writeByte(' ');
        }
        
        // Print title
        try self.stdout.print("{s}", .{title});
        
        // Print padding
        i = 0;
        while (i < padding) : (i += 1) {
            try self.stdout.writeByte(' ');
        }
        
        try self.stdout.print("\n\x1b[0m", .{});
        try self.drawHorizontalLine(total_width, '=', .bright_yellow);
        try self.stdout.print("\n", .{});
    }
    
    // Draw a status bar
    pub fn drawStatusBar(self: *TerminalUI, label: []const u8, value: []const u8, width: usize, filled_char: u8, empty_char: u8, percentage: f32, color: TextColor) !void {
        try self.print(label, .white, .bold);
        try self.stdout.print(": ", .{});
        try self.print(value, .bright_white, .normal);
        try self.stdout.print(" [", .{});
        
        const filled_f = percentage * @as(f32, @floatFromInt(width));
        const filled = @as(usize, @intFromFloat(filled_f));
        const empty = width - filled;
        
        try self.stdout.print("\x1b[{s}m", .{color.ansiCode()});
        
        var i: usize = 0;
        while (i < filled) : (i += 1) {
            try self.stdout.writeByte(filled_char);
        }
        
        try self.stdout.print("\x1b[0m", .{});
        
        i = 0;
        while (i < empty) : (i += 1) {
            try self.stdout.writeByte(empty_char);
        }
        
        try self.stdout.print("]\n", .{});
    }
    
    // Draw a menu with selectable options
    pub fn drawMenu(self: *TerminalUI, title: []const u8, options: []const []const u8, selected: usize) !void {
        try self.println(title, .bright_cyan, .bold);
        
        for (options, 0..) |option, i| {
            if (i == selected) {
                try self.print("> ", .bright_green, .bold);
                try self.println(option, .bright_green, .normal);
            } else {
                try self.print("  ", .white, .normal);
                try self.println(option, .white, .normal);
            }
        }
        
        try self.stdout.print("\n", .{});
    }
};

// Test terminal UI color and style functionality
test "Terminal UI color and style" {
    var buffer = std.ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();
    
    var mock_writer = MockWriter{ .buffer = buffer };
    
    var ui = TerminalUI{
        .stdout = mock_writer.writer(),
    };
    
    // Test different color and style combinations
    try ui.print("Test message", .green, .bold);
    try testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[1;32mTest message\x1b[0m") != null);
    
    // Clear buffer
    buffer.clearRetainingCapacity();
    
    // Test println
    try ui.println("Test line", .blue, .normal);
    try testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[0;34mTest line\x1b[0m\n") != null);
}

// Test drawing UI elements
test "Terminal UI elements" {
    var buffer = std.ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();
    
    var mock_writer = MockWriter{ .buffer = buffer };
    
    var ui = TerminalUI{
        .stdout = mock_writer.writer(),
    };
    
    // Test drawing a horizontal line
    try ui.drawHorizontalLine(5, '-', .cyan);
    try testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[36m-----\x1b[0m\n") != null);
    
    // Clear buffer
    buffer.clearRetainingCapacity();
    
    // Test drawing a title
    try ui.drawTitle("TEST");
    try testing.expect(std.mem.indexOf(u8, buffer.items, "TEST") != null);
    try testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[93m") != null); // bright_yellow color
}

// Test drawing a status bar
test "Terminal UI status bar" {
    var buffer = std.ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();
    
    var mock_writer = MockWriter{ .buffer = buffer };
    
    var ui = TerminalUI{
        .stdout = mock_writer.writer(),
    };
    
    // Test drawing a status bar
    try ui.drawStatusBar("Progress", "50%", 10, '#', '-', 0.5, .green);
    
    // Should have 5 filled characters and 5 empty characters
    try testing.expect(std.mem.indexOf(u8, buffer.items, "Progress") != null);
    try testing.expect(std.mem.indexOf(u8, buffer.items, "50%") != null);
    try testing.expect(std.mem.count(u8, buffer.items, "#") == 5);
    try testing.expect(std.mem.count(u8, buffer.items, "-") == 5);
}

// Test menu drawing
test "Terminal UI menu" {
    var buffer = std.ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();
    
    var mock_writer = MockWriter{ .buffer = buffer };
    
    var ui = TerminalUI{
        .stdout = mock_writer.writer(),
    };
    
    const options = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    try ui.drawMenu("Test Menu", &options, 1);
    
    // Check that all options are in the output
    try testing.expect(std.mem.indexOf(u8, buffer.items, "Test Menu") != null);
    try testing.expect(std.mem.indexOf(u8, buffer.items, "Option 1") != null);
    try testing.expect(std.mem.indexOf(u8, buffer.items, "Option 2") != null);
    try testing.expect(std.mem.indexOf(u8, buffer.items, "Option 3") != null);
    
    // Check that option 2 (index 1) is highlighted with ">"
    try testing.expect(std.mem.indexOf(u8, buffer.items, "> Option 2") != null);
}

// Run all UI tests
pub fn main() !void {
    testing.log_level = .debug;
    std.debug.print("\n[INFO] Starting TURMOIL UI component tests...\n", .{});
    const result = testing.run();
    if (result.skipped > 0) {
        std.debug.print("[INFO] {d} tests skipped\n", .{result.skipped});
    }
    if (result.failed > 0) {
        std.debug.print("[ERROR] {d} tests failed\n", .{result.failed});
        return error.TestFailed;
    }
    std.debug.print("[SUCCESS] All {d} UI tests passed!\n", .{result.passed});
    return result;
} 