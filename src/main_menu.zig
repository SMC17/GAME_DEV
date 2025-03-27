const std = @import("std");
const terminal_ui = @import("terminal_ui");
const player_data = @import("player_data");
const campaign_mode = @import("campaign_mode"); 
const arcade_mode = @import("arcade_mode");
const tycoon_mode = @import("tycoon_mode");
const character_mode = @import("character_mode");

pub const MainMenu = struct {
    allocator: std.mem.Allocator,
    ui: terminal_ui.TerminalUI,
    
    pub fn init(allocator: std.mem.Allocator) !MainMenu {
        return MainMenu{
            .allocator = allocator,
            .ui = terminal_ui.TerminalUI.init(std.io.getStdOut().writer(), allocator),
        };
    }
    
    pub fn deinit(self: *MainMenu) void {
        _ = self;
        // Nothing to clean up
    }
    
    pub fn run(self: *MainMenu) !void {
        var running = true;
        
        while (running) {
            try self.displayMenu();
            
            var choice_buffer: [10]u8 = undefined;
            const input = try std.io.getStdIn().reader().readUntilDelimiterOrEof(&choice_buffer, '\n');
            
            if (input) |user_input| {
                const trimmed = std.mem.trim(u8, user_input, &std.ascii.whitespace);
                if (trimmed.len > 0) {
                    const choice = std.fmt.parseInt(usize, trimmed, 10) catch 0;
                    switch (choice) {
                        1 => try campaign_mode.run(),
                        2 => try arcade_mode.run(),
                        3 => try tycoon_mode.run(),
                        4 => try character_mode.run(),
                        5 => running = false, // Exit the menu loop
                        else => {
                            try self.ui.println("\nInvalid choice. Please try again.", .red, .normal);
                            std.time.sleep(1 * std.time.ns_per_s);
                        },
                    }
                }
            }
        }
    }
    
    fn displayMenu(self: *MainMenu) !void {
        try self.ui.clear();
        try self.ui.drawTitle("TURMOIL: Oil Industry Simulator", .green);
        try self.ui.println("Welcome to the world of oil extraction and industry domination!", .white, .normal);
        try self.ui.drawDefaultHorizontalLine();
        
        try self.ui.println("Game Modes:", .yellow, .bold);
        try self.ui.println("1. Campaign Mode - Follow a story-driven campaign to build your oil empire", .white, .normal);
        try self.ui.println("2. Arcade Mode - Fast-paced oil extraction challenges", .white, .normal);
        try self.ui.println("3. Tycoon Mode - Manage all aspects of your oil company", .white, .normal);
        try self.ui.println("4. Character Mode - Develop your character's skills and relationships", .white, .normal);
        try self.ui.println("5. Quit Game", .white, .normal);
        
        try self.ui.drawDefaultHorizontalLine();
        try self.ui.print("Enter your choice (1-5): ", .yellow, .normal);
    }
}; 