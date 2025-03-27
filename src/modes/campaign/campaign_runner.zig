const std = @import("std");
const campaign_mode = @import("campaign_mode");
const narrative = @import("narrative");
const terminal_ui = @import("terminal_ui");
const player_data = @import("player_data");
const simulation = @import("simulation");

/// Main entry point for running the campaign mode
pub fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    
    const allocator = gpa.allocator();
    
    // Initialize the campaign
    var campaign = try campaign_mode.CampaignMode.init(allocator);
    defer campaign.deinit();
    
    // Initialize narrative system
    var narrative_manager = narrative.NarrativeManager.init(allocator);
    defer narrative_manager.deinit();
    
    try narrative_manager.createStoryEvents();
    
    // Initialize the terminal UI
    var ui = terminal_ui.TerminalUI.init(std.io.getStdOut().writer(), allocator);
    
    // Initialize player data if it doesn't already exist
    if (player_data.getGlobalPlayerData() == null) {
        try ui.clear();
        try ui.drawTitle("Character Setup", .blue);
        try ui.println("Before starting the campaign, please enter your details:", .white, .normal);
        
        try ui.print("Your Name: ", .yellow, .bold);
        var name_buffer: [100]u8 = undefined;
        const name_input = (try std.io.getStdIn().reader().readUntilDelimiterOrEof(&name_buffer, '\n')) orelse "";
        const player_name = std.mem.trim(u8, name_input, &std.ascii.whitespace);
        
        try ui.print("Your Company Name: ", .yellow, .bold);
        var company_buffer: [100]u8 = undefined;
        const company_input = (try std.io.getStdIn().reader().readUntilDelimiterOrEof(&company_buffer, '\n')) orelse "";
        const company_name = std.mem.trim(u8, company_input, &std.ascii.whitespace);
        
        // Use default names if nothing entered
        const final_player_name = if (player_name.len == 0) "Player" else player_name;
        const final_company_name = if (company_name.len == 0) "OilCorp" else company_name;
        
        try player_data.initGlobalPlayerData(allocator, final_player_name, final_company_name);
    }
    
    var running = true;
    var day: u32 = 1;
    var game_state: GameState = .normal;
    
    // Player data needed for narrative tracking
    var fields_owned: usize = 1;
    var reputation: f32 = 50.0; // Start with neutral reputation
    var technologies = std.ArrayList([]const u8).init(allocator);
    defer technologies.deinit();
    
    // Track if we're in a narrative event
    var in_narrative_event = false;
    
    // Main game loop
    while (running) {
        try ui.clear();
        
        // Check for narrative events if not already in one
        if (!in_narrative_event) {
            if (narrative_manager.checkTriggers(
                campaign.current_mission, 
                player_data.getGlobalPlayerData().?.money, 
                player_data.getGlobalPlayerData().?.oil_extracted,
                day,
                fields_owned,
                reputation,
                technologies.items
            ) != null) {
                in_narrative_event = true;
                game_state = .narrative;
            }
        }
        
        switch (game_state) {
            .normal => {
                // Display current mission
                if (campaign.getCurrentMission()) |mission| {
                    try displayMissionDetails(&ui, mission, player_data.getGlobalPlayerData().?);
                } else {
                    try ui.drawTitle("No Active Mission", .red);
                    try ui.println("Select a mission to begin your next objective.", .white, .italic);
                }
                
                try ui.drawDefaultHorizontalLine();
                
                // Company status
                try ui.println("Company Status:", .yellow, .bold);
                try ui.print("Money: $", .white, .normal);
                try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.2}", .{player_data.getGlobalPlayerData().?.money}), .green, .bold);
                try ui.print("Oil Extracted: ", .white, .normal);
                try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.2} barrels", .{player_data.getGlobalPlayerData().?.oil_extracted}), .cyan, .bold);
                try ui.print("Day: ", .white, .normal);
                try ui.println(try std.fmt.allocPrint(ui.allocator, "{d}", .{day}), .white, .bold);
                try ui.print("Reputation: ", .white, .normal);
                try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{reputation}), .blue, .bold);
                try ui.print("Oil Fields: ", .white, .normal);
                try ui.println(try std.fmt.allocPrint(ui.allocator, "{d}", .{fields_owned}), .magenta, .bold);
                
                // List available missions (excluding current one)
                try ui.drawDefaultHorizontalLine();
                try ui.println("Available Missions:", .yellow, .bold);
                var mission_count: usize = 0;
                for (campaign.missions.items) |mission| {
                    if (mission.unlocked and !mission.completed and mission.id != campaign.current_mission) {
                        try ui.print("• ", .white, .normal);
                        try ui.println(mission.title, .cyan, .bold);
                        try ui.println(try std.fmt.allocPrint(ui.allocator, "  {s}", .{mission.description}), .white, .normal);
                        mission_count += 1;
                    }
                }
                
                if (mission_count == 0) {
                    try ui.println("No other missions available at this time.", .white, .italic);
                }
                
                try ui.drawDefaultHorizontalLine();
                
                // Show relationships with key characters
                try ui.println("Key Relationships:", .yellow, .bold);
                var iterator = narrative_manager.characters.iterator();
                while (iterator.next()) |entry| {
                    const character = entry.value_ptr;
                    try ui.print(character.getDisplayName(), .white, .bold);
                    try ui.print(": ", .white, .normal);
                    
                    // Display relationship status with color coding
                    if (character.relationship >= 75.0) {
                        try ui.println("Excellent", .green, .bold);
                    } else if (character.relationship >= 50.0) {
                        try ui.println("Good", .green, .normal);
                    } else if (character.relationship >= 25.0) {
                        try ui.println("Positive", .cyan, .normal);
                    } else if (character.relationship >= -25.0) {
                        try ui.println("Neutral", .white, .normal);
                    } else if (character.relationship >= -50.0) {
                        try ui.println("Poor", .red, .normal);
                    } else if (character.relationship >= -75.0) {
                        try ui.println("Bad", .red, .bold);
                    } else {
                        try ui.println("Hostile", .red, .bold);
                    }
                }
                
                try ui.drawDefaultHorizontalLine();
                
                // Actions menu
                try ui.println("Actions:", .yellow, .bold);
                const options = [_][]const u8{
                    "Advance the game by one day",
                    "Manage oil fields",
                    "View mission history",
                    "Quit",
                };
                
                const choice = try ui.drawMenuAndGetChoice(&options, .white, .cyan);
                
                switch (choice) {
                    0 => {
                        // Advance game by one day
                        campaign.advanceDay();
                        day += 1;
                        
                        // Random events that increase resources (simplified simulation)
                        if (player_data.getGlobalPlayerData()) |data| {
                            const daily_oil = 20.0 + @as(f32, @floatFromInt(fields_owned)) * 10.0;
                            const daily_money = daily_oil * 1.5;
                            
                            data.oil_extracted += daily_oil;
                            data.money += daily_money;
                            
                            // Small chance to discover a new field
                            if (std.crypto.random.uintLessThan(u8, 100) < 5) {
                                fields_owned += 1;
                                try ui.println("\nYou discovered a new oil field!", .green, .bold);
                                std.time.sleep(2 * std.time.ns_per_s);
                            }
                            
                            // Small reputation changes randomly
                            if (std.crypto.random.uintLessThan(u8, 100) < 30) {
                                const rep_change = @as(f32, @floatFromInt(std.crypto.random.intRangeAtMost(i8, -3, 3)));
                                reputation += rep_change;
                                
                                // Clamp reputation
                                if (reputation > 100.0) reputation = 100.0;
                                if (reputation < 0.0) reputation = 0.0;
                            }
                        }
                        
                        // Check for mission completion
                        if (campaign.getCurrentMission()) |mission| {
                            const completed = campaign.checkMissionCompletion();
                            if (completed) {
                                try ui.clear();
                                try ui.drawTitle("Mission Complete!", .green);
                                try ui.println(try std.fmt.allocPrint(ui.allocator, "You have successfully completed: {s}", .{mission.title}), .white, .bold);
                                
                                // Apply rewards
                                if (player_data.getGlobalPlayerData()) |data| {
                                    data.money += mission.reward.money_bonus;
                                }
                                
                                if (mission.reward.new_oil_field) {
                                    fields_owned += 1;
                                }
                                
                                reputation += mission.reward.reputation_increase;
                                
                                // Unlock next missions
                                campaign.unlockMissions();
                                
                                try ui.drawDefaultHorizontalLine();
                                try ui.println("Press any key to continue...", .white, .normal);
                                _ = try std.io.getStdIn().reader().readByte();
                            }
                        }
                    },
                    1 => {
                        // Manage oil fields (placeholder)
                        try ui.clear();
                        try ui.drawTitle("Oil Field Management", .magenta);
                        try ui.println(try std.fmt.allocPrint(ui.allocator, "You own {d} oil fields.", .{fields_owned}), .white, .normal);
                        try ui.println("\nField management features coming soon...", .yellow, .italic);
                        try ui.println("\nPress any key to continue...", .white, .normal);
                        _ = try std.io.getStdIn().reader().readByte();
                    },
                    2 => {
                        // View mission history
                        try ui.clear();
                        try ui.drawTitle("Mission History", .blue);
                        var has_completed = false;
                        
                        for (campaign.missions.items) |mission| {
                            if (mission.completed) {
                                has_completed = true;
                                try ui.print("✓ ", .green, .bold);
                                try ui.println(mission.title, .white, .bold);
                                try ui.println(try std.fmt.allocPrint(ui.allocator, "  {s}", .{mission.description}), .white, .normal);
                                try ui.println("", .white, .normal);
                            }
                        }
                        
                        if (!has_completed) {
                            try ui.println("You haven't completed any missions yet.", .white, .italic);
                        }
                        
                        try ui.println("\nPress any key to continue...", .white, .normal);
                        _ = try std.io.getStdIn().reader().readByte();
                    },
                    3 => {
                        // Quit
                        running = false;
                    },
                    else => {},
                }
            },
            .narrative => {
                if (narrative_manager.getCurrentEvent()) |event| {
                    try ui.drawTitle(event.title, .yellow);
                    try ui.println(event.description, .white, .normal);
                    try ui.drawDefaultHorizontalLine();
                    
                    if (event.getCurrentDialogue()) |dialogue| {
                        // Display character name with appropriate styling
                        if (narrative_manager.getCharacter(dialogue.character)) |character| {
                            try ui.print(character.getDisplayName(), .cyan, .bold);
                            // Display role separately
                            const role_suffix = switch (character.role) {
                                .player => "",
                                .advisor => " (Advisor)",
                                .rival => " (Rival)",
                                .investor => " (Investor)",
                                .politician => " (Politician)",
                                .environmental_activist => " (Activist)",
                                .worker => " (Worker)",
                                .engineer => " (Engineer)",
                                .researcher => " (Researcher)",
                            };
                            try ui.print(role_suffix, .cyan, .italic);
                        } else {
                            try ui.print(dialogue.character, .cyan, .bold);
                        }
                        try ui.println(":", .white, .bold);
                        
                        // Display dialogue text
                        try ui.println(dialogue.text, .white, .normal);
                        
                        // Show choices if available
                        if (dialogue.choices) |choices| {
                            try ui.drawDefaultHorizontalLine();
                            try ui.println("Your response:", .yellow, .bold);
                            
                            var choice_texts = std.ArrayList([]const u8).init(allocator);
                            defer choice_texts.deinit();
                            
                            for (choices) |choice| {
                                try choice_texts.append(choice.text);
                            }
                            
                            const choice_index = try ui.drawMenuAndGetChoice(choice_texts.items, .white, .cyan);
                            
                            // Process the selected choice
                            _ = try narrative_manager.makeChoice(choice_index);
                        } else {
                            // If no choices, just press any key to continue
                            try ui.drawDefaultHorizontalLine();
                            try ui.println("Press any key to continue...", .white, .normal);
                            _ = try std.io.getStdIn().reader().readByte();
                            event.advanceDialogue(null);
                        }
                        
                        // Check if dialogue is complete
                        if (event.isDialogueComplete()) {
                            narrative_manager.completeCurrentEvent();
                            in_narrative_event = false;
                            game_state = .normal;
                        }
                    } else {
                        // If no dialogue left, end the event
                        narrative_manager.completeCurrentEvent();
                        in_narrative_event = false;
                        game_state = .normal;
                    }
                } else {
                    // Fallback in case something went wrong
                    in_narrative_event = false;
                    game_state = .normal;
                }
            },
        }
    }
}

/// Game state enum
const GameState = enum {
    normal,
    narrative,
};

/// The main display function for the current mission
fn displayMissionDetails(ui: *terminal_ui.TerminalUI, mission: *const campaign_mode.Mission, player: *player_data.PlayerData) !void {
    // Display mission header with difficulty
    const difficulty_color: terminal_ui.TextColor = switch (mission.difficulty) {
        .tutorial => .white,
        .easy => .green,
        .medium => .yellow,
        .hard => .magenta,
        .expert => .red,
    };
    
    try ui.drawTitle(mission.title, .cyan);
    
    // Show difficulty
    try ui.print("Difficulty: ", .white, .normal);
    try ui.println(@tagName(mission.difficulty), difficulty_color, .bold);
    
    // Description
    try ui.println(mission.description, .white, .normal);
    
    // Story text if available
    if (mission.story_text) |story| {
        try ui.drawDefaultHorizontalLine();
        try ui.println("Background:", .yellow, .italic);
        try ui.println(story, .white, .italic);
    }
    
    try ui.drawDefaultHorizontalLine();
    
    // Show mission objectives and progress
    try ui.println("Mission Objectives:", .yellow, .bold);
    
    switch (mission.objective_type) {
        .extract_oil => {
            try ui.print("Extract ", .white, .normal);
            try ui.print(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{mission.target_oil}), .green, .bold);
            try ui.println(" barrels of oil", .white, .normal);
            
            // Show progress bar
            const progress = player.oil_extracted / mission.target_oil;
            const progress_str = try std.fmt.allocPrint(ui.allocator, "{d:.0}%", .{progress * 100});
            try ui.drawStatusBar("Progress", progress_str, 40, '=', ' ', progress, .green);
        },
        .earn_money => {
            try ui.print("Earn $", .white, .normal);
            try ui.print(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{mission.target_money}), .green, .bold);
            
            // Show progress bar
            const progress = player.money / mission.target_money;
            const progress_str = try std.fmt.allocPrint(ui.allocator, "{d:.0}%", .{progress * 100});
            try ui.drawStatusBar("Progress", progress_str, 40, '=', ' ', progress, .green);
        },
        .upgrade_equipment => {
            try ui.println("Upgrade your drilling equipment", .white, .normal);
            
            // This would be connected to an equipment system
            try ui.drawStatusBar("Progress", "0%", 40, '=', ' ', 0.0, .green);
        },
        .hire_workers => {
            try ui.print("Hire ", .white, .normal);
            try ui.print(try std.fmt.allocPrint(ui.allocator, "{d}", .{mission.target_workers}), .green, .bold);
            try ui.println(" workers for your operation", .white, .normal);
            
            // This would be connected to a staffing system
            try ui.drawStatusBar("Progress", "0%", 40, '=', ' ', 0.0, .green);
        },
        .time_constraint => {
            try ui.print("Complete within ", .white, .normal);
            try ui.print(try std.fmt.allocPrint(ui.allocator, "{d}", .{mission.time_limit}), .yellow, .bold);
            try ui.println(" days", .white, .normal);
            
            // Show time remaining if the mission has started
            if (mission.start_day > 0) {
                const days_passed = @as(usize, @intCast(player_data.getGlobalPlayerData().?.game_day)) - mission.start_day;
                const time_progress = @as(f32, @floatFromInt(days_passed)) / @as(f32, @floatFromInt(mission.time_limit));
                
                const time_str = try std.fmt.allocPrint(ui.allocator, "{d:.0}%", .{(1.0 - time_progress) * 100});
                try ui.drawStatusBar("Time Remaining", time_str, 40, '=', ' ', 1.0 - time_progress, .yellow);
            }
        },
        .build_reputation => {
            try ui.print("Build reputation to ", .white, .normal);
            try ui.print(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{mission.target_reputation}), .blue, .bold);
            
            // Show progress bar
            const progress = player.reputation / mission.target_reputation;
            const progress_str = try std.fmt.allocPrint(ui.allocator, "{d:.0}%", .{progress * 100});
            try ui.drawStatusBar("Progress", progress_str, 40, '=', ' ', progress, .blue);
        },
        .discover_field => {
            try ui.println("Discover a new oil field", .white, .normal);
            
            // This would be connected to an exploration system
            try ui.drawStatusBar("Exploration Progress", "0%", 40, '=', ' ', 0.0, .magenta);
        },
        .research_tech => {
            if (mission.target_tech) |tech| {
                try ui.print("Research ", .white, .normal);
                try ui.println(tech, .cyan, .bold);
                
                // Check if the technology is already researched
                const has_tech = player.hasTechnology(tech);
                const progress: f32 = if (has_tech) 1.0 else 0.0;
                const progress_str = try std.fmt.allocPrint(ui.allocator, "{d:.0}%", .{progress * 100});
                try ui.drawStatusBar("Research Progress", progress_str, 40, '=', ' ', progress, .cyan);
            }
        },
        .environmental => {
            try ui.println("Maintain environmental standards", .white, .normal);
            
            if (mission.environmental_constraints) |constraints| {
                try ui.print("Max Pollution: ", .white, .normal);
                try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{constraints.max_pollution}), .green, .bold);
                
                if (constraints.requires_cleanup) {
                    try ui.println("Requires environmental cleanup operations", .green, .normal);
                }
                
                if (constraints.requires_green_tech) {
                    try ui.println("Requires green technology implementation", .green, .normal);
                }
            }
            
            // This would be connected to an environmental system
            try ui.drawStatusBar("Environmental Compliance", "0%", 40, '=', ' ', 0.0, .green);
        },
        .compete_market => {
            if (mission.target_competitor) |competitor| {
                try ui.print("Compete with ", .white, .normal);
                try ui.println(competitor, .red, .bold);
                try ui.println("Gain market share through higher production and profits", .white, .normal);
            }
            
            // This would be connected to a market competition system
            try ui.drawStatusBar("Market Competition", "0%", 40, '=', ' ', 0.0, .red);
        },
        .diplomacy => {
            if (mission.target_character) |character| {
                try ui.print("Build relationship with ", .white, .normal);
                try ui.println(character, .blue, .bold);
                try ui.print("Target relationship level: ", .white, .normal);
                try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{mission.target_relationship_level}), .blue, .bold);
            }
            
            // This would be connected to a relationship system
            try ui.drawStatusBar("Relationship", "0%", 40, '=', ' ', 0.0, .blue);
        },
        .crisis_management => {
            try ui.println("Successfully manage the crisis situation", .white, .normal);
            
            // This would be connected to a crisis management system
            try ui.drawStatusBar("Crisis Management", "0%", 40, '=', ' ', 0.0, .red);
        },
    }
    
    // Show any time constraints if they exist and are not the main objective
    if (mission.time_limit > 0 and mission.objective_type != .time_constraint) {
        try ui.drawDefaultHorizontalLine();
        try ui.println("Time Constraints:", .yellow, .bold);
        try ui.print("Complete within ", .white, .normal);
        try ui.print(try std.fmt.allocPrint(ui.allocator, "{d}", .{mission.time_limit}), .yellow, .bold);
        try ui.println(" days", .white, .normal);
        
        // Show time remaining if the mission has started
        if (mission.start_day > 0) {
            const days_passed = @as(usize, @intCast(player_data.getGlobalPlayerData().?.game_day)) - mission.start_day;
            const time_progress = @as(f32, @floatFromInt(days_passed)) / @as(f32, @floatFromInt(mission.time_limit));
            
            const time_str = try std.fmt.allocPrint(ui.allocator, "{d:.0}%", .{(1.0 - time_progress) * 100});
            try ui.drawStatusBar("Time Remaining", time_str, 40, '=', ' ', 1.0 - time_progress, .yellow);
        }
    }
    
    // Show environmental constraints if they exist
    if (mission.environmental_constraints != null and mission.objective_type != .environmental) {
        try ui.drawDefaultHorizontalLine();
        try ui.println("Environmental Constraints:", .green, .bold);
        
        const constraints = mission.environmental_constraints.?;
        try ui.print("Max Pollution: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{constraints.max_pollution}), .green, .bold);
        
        if (constraints.requires_cleanup) {
            try ui.println("Requires environmental cleanup operations", .green, .normal);
        }
        
        if (constraints.requires_green_tech) {
            try ui.println("Requires green technology implementation", .green, .normal);
        }
    }
    
    // Show mission rewards if not completed
    if (!mission.completed) {
        try ui.drawDefaultHorizontalLine();
        try ui.println("Rewards:", .green, .bold);
        
        if (mission.reward.money_bonus > 0) {
            try ui.print("• $", .white, .normal);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{mission.reward.money_bonus}), .green, .bold);
        }
        
        if (mission.reward.equipment_bonus) |equipment| {
            try ui.print("• ", .white, .normal);
            try ui.println(equipment, .cyan, .bold);
        }
        
        if (mission.reward.new_oil_field) {
            try ui.println("• Access to a new oil field", .cyan, .bold);
        }
        
        if (mission.reward.reputation_increase > 0) {
            try ui.print("• +", .white, .normal);
            try ui.print(try std.fmt.allocPrint(ui.allocator, "{d:.1}", .{mission.reward.reputation_increase}), .blue, .bold);
            try ui.println(" Reputation", .white, .normal);
        }
        
        if (mission.reward.technology_unlock) |tech| {
            try ui.print("• Technology: ", .white, .normal);
            try ui.println(tech, .magenta, .bold);
        }
        
        if (mission.reward.staff_bonus) |staff| {
            try ui.print("• Additional Staff: ", .white, .normal);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "{d} workers", .{staff}), .yellow, .bold);
        }
        
        if (mission.reward.special_contract) |contract| {
            try ui.print("• Special Contract: ", .white, .normal);
            try ui.println(contract, .green, .bold);
        }
    }
}

/// Display oil fields
fn displayOilFields(ui: *terminal_ui.TerminalUI, _: *simulation.SimulationEngine) !void {
    try ui.clear();
    try ui.drawTitle("Oil Fields", .cyan);
    
    // This would display actual oil fields from the simulation
    try ui.println("Oil Field #1", .green, .bold);
    try ui.println("  Size: Large", .white, .normal);
    try ui.println("  Extraction Rate: 20 barrels/day", .white, .normal);
    try ui.println("  Quality: High", .white, .normal);
    try ui.drawStatusBar("Remaining Oil", "75%", 40, '=', ' ', 0.75, .green);
    
    try ui.drawDefaultHorizontalLine();
    try ui.println("Press Enter to continue...", .white, .normal);
    
    var input_buffer: [10]u8 = undefined;
    _ = try std.io.getStdIn().reader().readUntilDelimiterOrEof(&input_buffer, '\n');
} 