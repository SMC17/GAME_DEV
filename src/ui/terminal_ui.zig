const std = @import("std");

/// Text color for terminal output
pub const TextColor = enum {
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
    
    /// Get the ANSI color code for this color
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

/// Text style for terminal output
pub const TextStyle = enum {
    normal,
    bold,
    italic,
    underline,
    
    /// Get the ANSI style code for this style
    pub fn ansiCode(self: TextStyle) []const u8 {
        return switch (self) {
            .normal => "0",
            .bold => "1",
            .italic => "3",
            .underline => "4",
        };
    }
};

/// Terminal UI component for rendering
pub const TerminalUI = struct {
    stdout: std.fs.File.Writer,
    
    /// Initialize a new terminal UI
    pub fn init() TerminalUI {
        return TerminalUI{
            .stdout = std.io.getStdOut().writer(),
        };
    }
    
    /// Clear the screen
    pub fn clear(self: *TerminalUI) !void {
        try self.stdout.print("\x1b[2J\x1b[H", .{});
    }
    
    /// Print a message with color and style
    pub fn print(self: *TerminalUI, msg: []const u8, color: TextColor, style: TextStyle) !void {
        try self.stdout.print("\x1b[{s};{s}m{s}\x1b[0m", .{style.ansiCode(), color.ansiCode(), msg});
    }
    
    /// Print a message with color and style, followed by a newline
    pub fn println(self: *TerminalUI, msg: []const u8, color: TextColor, style: TextStyle) !void {
        try self.print(msg, color, style);
        try self.stdout.print("\n", .{});
    }
    
    /// Draw a horizontal line
    pub fn drawHorizontalLine(self: *TerminalUI, width: usize, char: u8, color: TextColor) !void {
        try self.stdout.print("\x1b[{s}m", .{color.ansiCode()});
        
        var i: usize = 0;
        while (i < width) : (i += 1) {
            try self.stdout.writeByte(char);
        }
        
        try self.stdout.print("\x1b[0m\n", .{});
    }
    
    /// Draw a title banner
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
    
    /// Draw a status bar
    pub fn drawStatusBar(self: *TerminalUI, label: []const u8, value: []const u8, width: usize, filled_char: u8, empty_char: u8, percentage: f32, color: TextColor) !void {
        try self.print(label, .white, .bold);
        try self.stdout.print(": ", .{});
        try self.print(value, .bright_white, .normal);
        try self.stdout.print(" [", .{});
        
        const filled_f = percentage * @as(f32, @floatFromInt(width));
        const filled: usize = @intFromFloat(filled_f);
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
    
    /// Draw a menu with selectable options
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