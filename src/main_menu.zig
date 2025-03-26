const std = @import("std");
const terminal_ui = @import("ui/terminal_ui.zig");
const child_process = @import("std").process;

/// The available game modes
pub const GameMode = enum {
    simulation,
    campaign,
    arcade,
    tycoon,
    character,
    sandbox,
    
    /// Get the display name for this game mode
    pub fn displayName(self: GameMode) []const u8 {
        return switch (self) {
            .simulation => "Core Simulation",
            .campaign => "Single-Player Campaign",
            .arcade => "Arcade Mode",
            .tycoon => "Tycoon/GM Mode",
            .character => "Character-Building Mode",
            .sandbox => "Sandbox Mode",
        };
    }
    
    /// Get the description for this game mode
    pub fn description(self: GameMode) []const u8 {
        return switch (self) {
            .simulation => "The basic oil extraction simulation demo.",
            .campaign => "Experience a narrative journey from modest beginnings to oil industry dominance.",
            .arcade => "Fast-paced, score-based drilling challenges.",
            .tycoon => "Deep economic simulation with market dynamics and corporate management.",
            .character => "Develop unique characters with specialized skills and personal storylines.",
            .sandbox => "Experiment with all game systems in an open-ended environment.",
        };
    }
    
    /// Get the command to run this game mode
    pub fn runCommand(self: GameMode) []const u8 {
        return switch (self) {
            .simulation => "zig build run",
            .campaign => "zig build run-campaign",
            .arcade => "zig build run-arcade",
            .tycoon => "echo \"Tycoon mode not yet implemented\"",
            .character => "echo \"Character mode not yet implemented\"",
            .sandbox => "echo \"Sandbox mode not yet implemented\"",
        };
    }
};

/// The main menu for the game
pub const MainMenu = struct {
    ui: terminal_ui.TerminalUI,
    selected_mode: GameMode,
    should_quit: bool,
    
    /// Initialize a new main menu
    pub fn init() MainMenu {
        return MainMenu{
            .ui = terminal_ui.TerminalUI.init(),
            .selected_mode = .campaign,
            .should_quit = false,
        };
    }
    
    /// Run the main menu
    pub fn run(self: *MainMenu) !void {
        while (!self.should_quit) {
            try self.renderMenu();
            try self.handleInput();
        }
    }
    
    /// Render the main menu
    fn renderMenu(self: *MainMenu) !void {
        try self.ui.clear();
        
        try self.ui.drawTitle("TURMOIL - OIL INDUSTRY SIMULATOR");
        
        try self.ui.println("Welcome to TURMOIL, an ambitious oil industry simulation game!", .bright_white, .bold);
        try self.ui.println("Select a game mode to start playing:", .white, .normal);
        try self.ui.stdout.print("\n", .{});
        
        // Display game modes
        const modes = [_]GameMode{ .simulation, .campaign, .arcade, .tycoon, .character, .sandbox };
        const mode_names = [_][]const u8{
            "Core Simulation",
            "Single-Player Campaign",
            "Arcade Mode",
            "Tycoon/GM Mode (Coming Soon)",
            "Character-Building Mode (Coming Soon)",
            "Sandbox Mode (Coming Soon)",
        };
        
        var selected_index: usize = 0;
        inline for (modes, 0..) |mode, i| {
            if (mode == self.selected_mode) {
                selected_index = i;
                break;
            }
        }
        
        try self.ui.drawMenu("Game Modes:", &mode_names, selected_index);
        
        // Display description for the selected mode
        try self.ui.println("Description:", .bright_cyan, .bold);
        try self.ui.println(self.selected_mode.description(), .white, .normal);
        try self.ui.stdout.print("\n", .{});
        
        // Navigation instructions
        try self.ui.println("Controls:", .bright_cyan, .bold);
        try self.ui.println("* Use Up/Down Arrows to navigate", .white, .normal);
        try self.ui.println("* Press Enter to select", .white, .normal);
        try self.ui.println("* Press Q to quit", .white, .normal);
    }
    
    /// Handle user input
    fn handleInput(self: *MainMenu) !void {
        try self.ui.stdout.print("Enter command (n=next, p=previous, s=select, q=quit): ", .{});
        
        var buf: [100]u8 = undefined;
        if (try self.ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
            if (input.len == 0) {
                return;
            }
            
            switch (input[0]) {
                'n', 'N' => {
                    // Next option
                    self.selected_mode = switch (self.selected_mode) {
                        .simulation => .campaign,
                        .campaign => .arcade,
                        .arcade => .tycoon,
                        .tycoon => .character,
                        .character => .sandbox,
                        .sandbox => .simulation,
                    };
                },
                'p', 'P' => {
                    // Previous option
                    self.selected_mode = switch (self.selected_mode) {
                        .simulation => .sandbox,
                        .campaign => .simulation,
                        .arcade => .campaign,
                        .tycoon => .arcade,
                        .character => .tycoon,
                        .sandbox => .character,
                    };
                },
                's', 'S', '\r', '\n' => {
                    // Select option
                    try self.runSelectedMode();
                },
                'q', 'Q' => {
                    self.should_quit = true;
                },
                else => {},
            }
        }
    }
    
    /// Run the selected game mode
    fn runSelectedMode(self: *MainMenu) !void {
        try self.ui.clear();
        try self.ui.println("Launching...", .bright_green, .bold);
        try self.ui.println(self.selected_mode.displayName(), .bright_white, .bold);
        try self.ui.stdout.print("\n", .{});
        
        // Run the appropriate command for the selected mode
        const command = self.selected_mode.runCommand();
        try self.ui.println("Running command:", .white, .bold);
        try self.ui.println(command, .bright_white, .normal);
        try self.ui.stdout.print("\n", .{});
        
        // Since we can't easily run child processes in this environment,
        // we'll just simulate the command being run
        try self.ui.println("Simulating command execution...", .yellow, .italic);
        try self.ui.println("(In a real implementation, this would actually run the command)", .yellow, .italic);
        try self.ui.stdout.print("\n", .{});
        
        try self.ui.stdout.print("\nPress Enter to return to the menu...", .{});
        var wait_buf: [10]u8 = undefined;
        _ = try self.ui.stdout.context.reader().readUntilDelimiterOrEof(wait_buf[0..], '\n');
    }
}; 