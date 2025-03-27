const std = @import("std");
const main_menu = @import("main_menu.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var menu = try main_menu.MainMenu.init(allocator);
    defer menu.deinit();
    
    try menu.run();
} 