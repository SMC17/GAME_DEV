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

/// Chart types for visualization
pub const ChartType = enum {
    line,
    bar,
    area,
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
    
    /// Draw a line chart for visualizing time-series data
    pub fn drawLineChart(self: *TerminalUI, title: []const u8, data: []const f32, chart_width: usize, chart_height: usize, color: TextColor) !void {
        if (data.len == 0 or chart_height == 0 or chart_width == 0) {
            return;
        }
        
        try self.println(title, .bright_cyan, .bold);
        
        // Find min and max values
        var min_value: f32 = data[0];
        var max_value: f32 = data[0];
        
        for (data) |value| {
            min_value = @min(min_value, value);
            max_value = @max(max_value, value);
        }
        
        // Ensure range isn't zero to avoid division by zero
        if (min_value == max_value) {
            max_value += 1.0;
        }
        
        // Create a 2D grid for the chart
        var grid = try std.ArrayList(std.ArrayList(u8)).initCapacity(std.heap.page_allocator, chart_height);
        defer {
            for (grid.items) |row| {
                row.deinit();
            }
            grid.deinit();
        }
        
        for (0..chart_height) |_| {
            var row = std.ArrayList(u8).init(std.heap.page_allocator);
            try row.appendNTimes(' ', chart_width);
            try grid.append(row);
        }
        
        // Calculate plot points
        const x_step = if (data.len > 1) @as(f32, @floatFromInt(chart_width - 1)) / @as(f32, @floatFromInt(data.len - 1)) else 0;
        const y_range = max_value - min_value;
        
        for (data, 0..) |value, i| {
            const x = @as(usize, @intFromFloat(@as(f32, @floatFromInt(i)) * x_step));
            const normalized = if (y_range > 0) (value - min_value) / y_range else 0.5;
            const y = chart_height - 1 - @as(usize, @intFromFloat(normalized * @as(f32, @floatFromInt(chart_height - 1))));
            
            // Ensure we're in bounds
            if (x < chart_width and y < chart_height) {
                grid.items[y].items[x] = '•';
            }
        }
        
        // Draw top border
        try self.stdout.print("┌", .{});
        for (0..chart_width) |_| {
            try self.stdout.print("─", .{});
        }
        try self.stdout.print("┐\n", .{});
        
        // Draw the chart
        for (grid.items) |row| {
            try self.stdout.print("│", .{});
            
            try self.stdout.print("\x1b[{s}m", .{color.ansiCode()});
            for (row.items) |cell| {
                try self.stdout.writeByte(cell);
            }
            try self.stdout.print("\x1b[0m", .{});
            
            try self.stdout.print("│\n", .{});
        }
        
        // Draw bottom border
        try self.stdout.print("└", .{});
        for (0..chart_width) |_| {
            try self.stdout.print("─", .{});
        }
        try self.stdout.print("┘\n", .{});
        
        // Add some labels for context
        try self.print("Min: ", .white, .normal);
        try self.println(try std.fmt.allocPrint(std.heap.page_allocator, "{d:.2}", .{min_value}), .bright_white, .normal);
        try self.print("Max: ", .white, .normal);
        try self.println(try std.fmt.allocPrint(std.heap.page_allocator, "{d:.2}", .{max_value}), .bright_white, .normal);
        
        try self.stdout.print("\n", .{});
    }
    
    /// Draw a bar chart for visualizing categorical data
    pub fn drawBarChart(self: *TerminalUI, title: []const u8, categories: []const []const u8, values: []const f32, max_width: usize, color: TextColor) !void {
        if (categories.len == 0 or categories.len != values.len) {
            return;
        }
        
        try self.println(title, .bright_cyan, .bold);
        
        // Find max value for scaling
        var max_value: f32 = 0;
        for (values) |value| {
            max_value = @max(max_value, value);
        }
        
        // Ensure max_value isn't zero to avoid division by zero
        if (max_value == 0) {
            max_value = 1;
        }
        
        // Find longest category name for alignment
        var max_category_len: usize = 0;
        for (categories) |category| {
            max_category_len = @max(max_category_len, category.len);
        }
        
        // Draw each bar
        for (categories, 0..) |category, i| {
            const value = values[i];
            const normalized = value / max_value;
            const bar_width = @as(usize, @intFromFloat(normalized * @as(f32, @floatFromInt(max_width))));
            
            // Pad the category name for alignment
            try self.stdout.print("{s: <[1]}", .{category, max_category_len + 2});
            
            // Draw the bar
            try self.stdout.print("\x1b[{s}m", .{color.ansiCode()});
            for (0..bar_width) |_| {
                try self.stdout.print("█", .{});
            }
            try self.stdout.print("\x1b[0m", .{});
            
            // Print the value
            try self.println(try std.fmt.allocPrint(std.heap.page_allocator, " {d:.2}", .{value}), .bright_white, .normal);
        }
        
        try self.stdout.print("\n", .{});
    }
    
    /// Draw a heatmap for 2D data
    pub fn drawHeatmap(self: *TerminalUI, title: []const u8, data: []const []const f32, color_map: []const TextColor) !void {
        if (data.len == 0 or data[0].len == 0) {
            return;
        }
        
        try self.println(title, .bright_cyan, .bold);
        
        // Find min and max values
        var min_value: f32 = data[0][0];
        var max_value: f32 = data[0][0];
        
        for (data) |row| {
            for (row) |value| {
                min_value = @min(min_value, value);
                max_value = @max(max_value, value);
            }
        }
        
        // Ensure range isn't zero to avoid division by zero
        if (min_value == max_value) {
            max_value += 1.0;
        }
        
        // Draw the heatmap
        try self.stdout.print("┌", .{});
        for (0..data[0].len) |_| {
            try self.stdout.print("─", .{});
        }
        try self.stdout.print("┐\n", .{});
        
        for (data) |row| {
            try self.stdout.print("│", .{});
            
            for (row) |value| {
                const normalized = if (max_value > min_value) (value - min_value) / (max_value - min_value) else 0.5;
                const color_index = @as(usize, @intFromFloat(normalized * @as(f32, @floatFromInt(color_map.len - 1))));
                
                try self.stdout.print("\x1b[{s}m█\x1b[0m", .{color_map[color_index].ansiCode()});
            }
            
            try self.stdout.print("│\n", .{});
        }
        
        try self.stdout.print("└", .{});
        for (0..data[0].len) |_| {
            try self.stdout.print("─", .{});
        }
        try self.stdout.print("┘\n", .{});
        
        // Add some labels for context
        try self.print("Min: ", .white, .normal);
        try self.println(try std.fmt.allocPrint(std.heap.page_allocator, "{d:.2}", .{min_value}), .bright_white, .normal);
        try self.print("Max: ", .white, .normal);
        try self.println(try std.fmt.allocPrint(std.heap.page_allocator, "{d:.2}", .{max_value}), .bright_white, .normal);
        
        try self.stdout.print("\n", .{});
    }
}; 