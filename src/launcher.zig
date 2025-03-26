const std = @import("std");
const main_menu = @import("main_menu.zig");

pub fn main() !void {
    // Initialize the main menu
    var menu = main_menu.MainMenu.init();
    
    // Run the main menu
    try menu.run();
} 