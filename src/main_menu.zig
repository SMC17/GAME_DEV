const std = @import("std");
const terminal_ui = @import("ui/terminal_ui.zig");
const child_process = @import("std").process;
const player_data = @import("player_data");

/// The available game modes
pub const GameMode = enum {
    simulation,
    campaign,
    arcade,
    tycoon,
    character,
    sandbox,
    achievements,
    
    /// Get the display name for this game mode
    pub fn displayName(self: GameMode) []const u8 {
        return switch (self) {
            .simulation => "Core Simulation",
            .campaign => "Single-Player Campaign",
            .arcade => "Arcade Mode",
            .tycoon => "Tycoon/GM Mode",
            .character => "Character-Building Mode",
            .sandbox => "Sandbox Mode",
            .achievements => "Achievements & Stats",
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
            .achievements => "View your achievements, stats, and progress across all game modes.",
        };
    }
    
    /// Get the command to run this game mode
    pub fn runCommand(self: GameMode) []const u8 {
        return switch (self) {
            .simulation => "zig build run",
            .campaign => "zig build run-campaign",
            .arcade => "zig build run-arcade",
            .tycoon => "zig build run-tycoon",
            .character => "zig build run-character",
            .sandbox => "zig build run-sandbox",
            .achievements => "zig build run-achievements",
        };
    }
};

/// The main menu for the game
pub const MainMenu = struct {
    ui: terminal_ui.TerminalUI,
    selected_mode: GameMode,
    should_quit: bool,
    has_player_data: bool,
    allocator: std.mem.Allocator,
    
    /// Initialize a new main menu
    pub fn init(allocator: std.mem.Allocator) !MainMenu {
        // Initialize player data system
        var has_data = true;
        player_data.initGlobalPlayerData(allocator) catch |err| {
            std.debug.print("Warning: Failed to initialize player data: {any}\n", .{err});
            has_data = false;
        };
        
        return MainMenu{
            .ui = terminal_ui.TerminalUI.init(allocator),
            .selected_mode = .campaign,
            .should_quit = false,
            .has_player_data = has_data,
            .allocator = allocator,
        };
    }
    
    /// Cleanup resources
    pub fn deinit(self: *MainMenu) void {
        // Clean up player data
        _ = self; // Use parameter to avoid warning
        player_data.closeGlobalPlayerData();
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
        
        // Show player stats if available
        if (self.has_player_data) {
            if (player_data.getGlobalPlayerData()) |data| {
                try self.ui.println("Player Stats:", .bright_green, .bold);
                try self.ui.print("Character Level: ", .white, .normal);
                try self.ui.println(try std.fmt.allocPrint(self.allocator, "{d}", .{data.character_level}), .bright_white, .bold);
                
                try self.ui.print("Achievements: ", .white, .normal);
                try self.ui.println(try std.fmt.allocPrint(self.allocator, "{d}", .{data.getAchievementCount()}), .bright_white, .bold);
                
                try self.ui.print("Total Earnings: ", .white, .normal);
                try self.ui.println(try std.fmt.allocPrint(self.allocator, "${d:.2}", .{data.total_earnings}), .bright_green, .bold);
                
                try self.ui.print("Company Value: ", .white, .normal);
                try self.ui.println(try std.fmt.allocPrint(self.allocator, "${d:.2}", .{data.company_value}), .bright_green, .bold);
                
                // Show skills
                try self.ui.println("\nSkills:", .bright_cyan, .bold);
                
                const skills = [_]struct { name: []const u8, value: f32 }{
                    .{ .name = "Management", .value = data.management_skill },
                    .{ .name = "Engineering", .value = data.engineering_skill },
                    .{ .name = "Negotiation", .value = data.negotiation_skill },
                    .{ .name = "Exploration", .value = data.exploration_skill },
                    .{ .name = "Environmental", .value = data.environmental_skill },
                };
                
                for (skills) |skill| {
                    const percentage = skill.value / 10.0; // Skills range from 0-10
                    const skill_color: terminal_ui.TextColor = if (skill.value > 7.0) .bright_green 
                        else if (skill.value > 4.0) .yellow else .white;
                    
                    try self.ui.drawStatusBar(skill.name, 
                        try std.fmt.allocPrint(self.allocator, "{d:.1}", .{skill.value}), 
                        10, '#', '-', percentage, skill_color);
                }
                
                try self.ui.stdout.print("\n", .{});
            }
        }
        
        // Display game modes
        const modes = [_]GameMode{ 
            .simulation, .campaign, .arcade, .tycoon, 
            .character, .sandbox, .achievements 
        };
        
        // Get display names
        var mode_names: [modes.len][]const u8 = undefined;
        for (modes, 0..) |mode, i| {
            mode_names[i] = mode.displayName();
        }
        
        var selected_index: usize = 0;
        for (modes, 0..) |mode, i| {
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
        try self.ui.println("* Use N/P to navigate next/previous", .white, .normal);
        try self.ui.println("* Press S to select", .white, .normal);
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
                        .sandbox => .achievements,
                        .achievements => .simulation,
                    };
                },
                'p', 'P' => {
                    // Previous option
                    self.selected_mode = switch (self.selected_mode) {
                        .simulation => .achievements,
                        .campaign => .simulation,
                        .arcade => .campaign,
                        .tycoon => .arcade,
                        .character => .tycoon,
                        .sandbox => .character,
                        .achievements => .sandbox,
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
        
        // Special handling for achievements view
        if (self.selected_mode == .achievements) {
            try self.viewAchievementsScreen();
            return;
        }
        
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
    
    /// View achievements and player stats
    fn viewAchievementsScreen(self: *MainMenu) !void {
        if (!self.has_player_data) {
            try self.ui.println("No player data available. Start playing to earn achievements!", .yellow, .italic);
            try self.ui.stdout.print("\nPress Enter to return to the menu...", .{});
            var wait_buf: [10]u8 = undefined;
            _ = try self.ui.stdout.context.reader().readUntilDelimiterOrEof(wait_buf[0..], '\n');
            return;
        }
        
        const data_opt = player_data.getGlobalPlayerData();
        if (data_opt == null) {
            try self.ui.println("Error: Player data system initialized but data not available.", .bright_red, .bold);
            try self.ui.stdout.print("\nPress Enter to return to the menu...", .{});
            var wait_buf: [10]u8 = undefined;
            _ = try self.ui.stdout.context.reader().readUntilDelimiterOrEof(wait_buf[0..], '\n');
            return;
        }
        
        const data = data_opt.?;
        
        try self.ui.drawTitle("PLAYER ACHIEVEMENTS & STATS");
        
        // Display character info
        try self.ui.println("Character Progress:", .bright_cyan, .bold);
        try self.ui.print("Level: ", .white, .normal);
        try self.ui.println(try std.fmt.allocPrint(self.allocator, "{d}", .{data.character_level}), .bright_white, .bold);
        
        // Skills
        try self.ui.println("\nSkills:", .bright_yellow, .bold);
        
        const skills = [_]struct { name: []const u8, value: f32, color: terminal_ui.TextColor }{
            .{ .name = "Management", .value = data.management_skill, .color = .bright_green },
            .{ .name = "Engineering", .value = data.engineering_skill, .color = .bright_cyan },
            .{ .name = "Negotiation", .value = data.negotiation_skill, .color = .bright_yellow },
            .{ .name = "Exploration", .value = data.exploration_skill, .color = .bright_magenta },
            .{ .name = "Environmental", .value = data.environmental_skill, .color = .bright_blue },
        };
        
        for (skills) |skill| {
            const percentage = skill.value / 10.0; 
            try self.ui.drawStatusBar(skill.name, 
                try std.fmt.allocPrint(self.allocator, "{d:.1}/10.0", .{skill.value}), 
                20, '#', '-', percentage, skill.color);
        }
        
        // Company stats
        try self.ui.println("\nCompany Stats:", .bright_cyan, .bold);
        try self.ui.print("Reputation: ", .white, .normal);
        const rep_color: terminal_ui.TextColor = if (data.company_reputation < 30.0) .red 
            else if (data.company_reputation < 70.0) .yellow else .bright_green;
        try self.ui.println(try std.fmt.allocPrint(self.allocator, "{d:.1}%", .{data.company_reputation}), rep_color, .bold);
        
        try self.ui.print("Total Earnings: ", .white, .normal);
        try self.ui.println(try std.fmt.allocPrint(self.allocator, "${d:.2}", .{data.total_earnings}), .bright_green, .bold);
        
        try self.ui.print("Company Value: ", .white, .normal);
        try self.ui.println(try std.fmt.allocPrint(self.allocator, "${d:.2}", .{data.company_value}), .bright_white, .bold);
        
        try self.ui.print("Largest Oilfield: ", .white, .normal);
        try self.ui.println(try std.fmt.allocPrint(self.allocator, "{d:.1} barrels", .{data.largest_oilfield_size}), .bright_yellow, .bold);
        
        // Unlocked regions
        try self.ui.println("\nUnlocked Regions:", .bright_cyan, .bold);
        var region_count: usize = 0;
        var region_iter = data.unlocked_regions.iterator();
        while (region_iter.next()) |entry| {
            if (entry.value_ptr.*) {
                try self.ui.print(try std.fmt.allocPrint(self.allocator, "{s} ", .{entry.key_ptr.*}), .bright_blue, .normal);
                region_count += 1;
            }
        }
        
        if (region_count == 0) {
            try self.ui.println("None unlocked yet", .yellow, .italic);
        } else {
            try self.ui.stdout.print("\n", .{});
        }
        
        // Achievements
        try self.ui.println("\nAchievements:", .bright_cyan, .bold);
        var achievement_count: usize = 0;
        var achievement_iter = data.achievements.iterator();
        while (achievement_iter.next()) |entry| {
            if (entry.value_ptr.*) {
                try self.ui.println(try std.fmt.allocPrint(self.allocator, "* {s}", .{entry.key_ptr.*}), .bright_green, .normal);
                achievement_count += 1;
            }
        }
        
        if (achievement_count == 0) {
            try self.ui.println("No achievements yet. Keep playing to earn them!", .yellow, .italic);
        }
        
        try self.ui.stdout.print("\nPress Enter to return to the menu...", .{});
        var wait_buf: [10]u8 = undefined;
        _ = try self.ui.stdout.context.reader().readUntilDelimiterOrEof(wait_buf[0..], '\n');
    }
}; 