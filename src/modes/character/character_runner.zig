const std = @import("std");
const character_mode = @import("character_mode.zig");
const terminal_ui = @import("terminal_ui");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Initialize the UI
    var ui = terminal_ui.TerminalUI.init(std.io.getStdOut().writer(), allocator);
    
    try ui.clear();
    try ui.drawTitle("TURMOIL: Character Mode", .cyan);
    
    try ui.println("Welcome to Character Mode! Build your career in the oil industry.", .bright_green, .bold);
    try ui.println("Develop skills, complete quests, and forge your own path to success.", .white, .normal);
    try ui.stdout.print("\n", .{});
    
    // Character creation
    const character_name = try characterCreation(&ui, allocator);
    
    // Character background selection
    const background = try backgroundSelection(&ui, allocator);
    
    // Trait selection
    const trait = try traitSelection(&ui, allocator);
    
    // Initialize the game
    var game = try character_mode.CharacterMode.init(allocator, character_name, background);
    defer game.deinit();
    
    // Add the selected trait
    try game.character.addTrait(trait);
    
    // Add initial quest
    if (try game.quest_manager.generateQuest(game.character.level)) |quest| {
        try game.character.addQuest(quest);
    }
    
    // Main game loop
    var running = true;
    var selected_menu_item: usize = 0;
    
    while (running) {
        try ui.clear();
        try ui.drawTitle("TURMOIL: Character Mode");
        
        // Show character info
        try ui.println("Character Status:", .bright_cyan, .bold);
        try ui.print("Name: ", .white, .normal);
        try ui.println(game.character.name, .bright_white, .bold);
        
        try ui.print("Level: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d}", .{game.character.level}), .bright_green, .bold);
        
        try ui.print("XP: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d}/{d}", .{game.character.total_xp, (game.character.level + 1) * 1000}), .bright_white, .normal);
        
        try ui.print("Cash: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{game.character.money}), .bright_green, .bold);
        
        try ui.print("Reputation: ", .white, .normal);
        const rep_percentage = game.character.reputation * 100.0;
        const rep_color: terminal_ui.TextColor = if (rep_percentage < 30.0) .red else if (rep_percentage < 70.0) .yellow else .bright_green;
        try ui.println(try std.fmt.allocPrint(allocator, "{d:.1}%", .{rep_percentage}), rep_color, .normal);
        
        try ui.print("Background: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(game.character.background)}), .bright_white, .bold);
        
        try ui.stdout.print("\n", .{});
        
        // Show traits
        try ui.println("Character Traits:", .bright_cyan, .bold);
        if (game.character.traits.items.len == 0) {
            try ui.println("No traits assigned yet.", .yellow, .italic);
        } else {
            for (game.character.traits.items) |char_trait| {
                try ui.println(try std.fmt.allocPrint(allocator, "{s}: {s}", .{@tagName(char_trait), char_trait.getDescription()}), .white, .normal);
            }
        }
        
        try ui.stdout.print("\n", .{});
        
        // Show skills
        try ui.println("Skills:", .bright_cyan, .bold);
        for (game.character.skills) |skill| {
            try ui.print(try std.fmt.allocPrint(allocator, "{s}: ", .{@tagName(skill.skill_type)}), .white, .bold);
            try ui.print(try std.fmt.allocPrint(allocator, "Level {d} ", .{skill.level}), .bright_white, .normal);
            
            // Progress bar to next level
            const progress = skill.getLevelProgress();
            try ui.drawStatusBar("", try std.fmt.allocPrint(allocator, "{d:.0}%", .{progress * 100.0}), 20, '#', '-', progress, .bright_green);
        }
        
        try ui.stdout.print("\n", .{});
        
        // Show active quests
        try ui.println("Active Quests:", .bright_cyan, .bold);
        if (game.character.active_quests.items.len == 0) {
            try ui.println("No active quests. Check back soon!", .yellow, .italic);
        } else {
            for (game.character.active_quests.items) |quest| {
                try ui.println(quest.title, .bright_white, .bold);
                try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{quest.description}), .white, .normal);
                
                const progress = quest.getProgressPercentage();
                try ui.drawStatusBar("Progress", try std.fmt.allocPrint(allocator, "{d:.1}%", .{progress * 100.0}), 20, '#', '-', progress, .bright_cyan);
                
                try ui.print("Rewards: ", .white, .normal);
                try ui.println(try std.fmt.allocPrint(allocator, "{d} XP, ${d:.2}", .{quest.reward_xp, quest.reward_money}), .bright_yellow, .normal);
                try ui.stdout.print("\n", .{});
            }
        }
        
        // Day indicator
        try ui.println(try std.fmt.allocPrint(allocator, "Day {d}", .{game.current_day}), .bright_blue, .bold);
        try ui.stdout.print("\n", .{});
        
        // Menu options
        const menu_options = [_][]const u8{
            "Advance Day",
            "Train Skills",
            "View Skill Details",
            "View Completed Quests",
            "Quit Game",
        };
        
        try ui.drawMenu("Actions:", &menu_options, selected_menu_item);
        
        // Get user input
        try ui.stdout.print("Enter command (n=next, p=previous, s=select, q=quit): ", .{});
        
        var buf: [100]u8 = undefined;
        if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
            if (input.len == 0) {
                continue;
            }
            
            switch (input[0]) {
                'n', 'N' => {
                    // Navigate to next menu item
                    selected_menu_item = (selected_menu_item + 1) % menu_options.len;
                },
                'p', 'P' => {
                    // Navigate to previous menu item
                    if (selected_menu_item == 0) {
                        selected_menu_item = menu_options.len - 1;
                    } else {
                        selected_menu_item -= 1;
                    }
                },
                's', 'S', '\r', '\n' => {
                    // Process selected action
                    switch (selected_menu_item) {
                        0 => { // Advance Day
                            try game.advanceDay();
                            
                            // Show skill progress if any
                            var had_level_up = false;
                            for (game.character.skills) |skill| {
                                if (skill.level > 1) {
                                    had_level_up = true;
                                    break;
                                }
                            }
                            
                            if (had_level_up) {
                                try ui.clear();
                                try ui.drawTitle("Day Summary");
                                try ui.println("You've gained experience in your skills:", .bright_green, .bold);
                                
                                for (game.character.skills) |skill| {
                                    try ui.print(try std.fmt.allocPrint(allocator, "{s}: ", .{@tagName(skill.skill_type)}), .white, .bold);
                                    try ui.println(try std.fmt.allocPrint(allocator, "Level {d}", .{skill.level}), .bright_white, .normal);
                                }
                                
                                try ui.stdout.print("\nPress Enter to continue...", .{});
                                _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                            }
                            
                            // Show quest completion if any
                            if (game.character.completed_quests.items.len > 0) {
                                const latest_quest = game.character.completed_quests.items[game.character.completed_quests.items.len - 1];
                                
                                try ui.clear();
                                try ui.drawTitle("Quest Completed!");
                                try ui.println(latest_quest.title, .bright_green, .bold);
                                try ui.println(latest_quest.description, .white, .normal);
                                try ui.stdout.print("\n", .{});
                                
                                try ui.println("Rewards:", .bright_cyan, .bold);
                                try ui.println(try std.fmt.allocPrint(allocator, "XP: {d}", .{latest_quest.reward_xp}), .bright_yellow, .normal);
                                try ui.println(try std.fmt.allocPrint(allocator, "Money: ${d:.2}", .{latest_quest.reward_money}), .bright_green, .normal);
                                
                                try ui.stdout.print("\nPress Enter to continue...", .{});
                                _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                            }
                        },
                        1 => { // Train Skills
                            try trainSkills(&ui, allocator, &game);
                        },
                        2 => { // View Skill Details
                            try viewSkillDetails(&ui, allocator, &game);
                        },
                        3 => { // View Completed Quests
                            try viewCompletedQuests(&ui, allocator, &game);
                        },
                        4 => { // Quit Game
                            running = false;
                        },
                        else => {},
                    }
                },
                'q', 'Q' => {
                    running = false;
                },
                else => {},
            }
        }
    }
    
    try ui.clear();
    try ui.drawTitle("TURMOIL: Character Mode");
    try ui.println("Thank you for playing the Character Mode demo!", .bright_green, .bold);
    try ui.println("Character summary:", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "Name: {s}", .{game.character.name}), .bright_white, .bold);
    try ui.println(try std.fmt.allocPrint(allocator, "Level: {d}", .{game.character.level}), .bright_green, .bold);
    try ui.println(try std.fmt.allocPrint(allocator, "Wealth: ${d:.2}", .{game.character.money}), .bright_green, .bold);
    try ui.println(try std.fmt.allocPrint(allocator, "Completed Quests: {d}", .{game.character.completed_quests.items.len}), .bright_yellow, .bold);
    try ui.stdout.print("\n", .{});
}

/// Character creation interface
fn characterCreation(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator) ![]const u8 {
    try ui.println("Enter your character's name:", .bright_cyan, .bold);
    
    var buf: [100]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
        if (input.len == 0) {
            return try allocator.dupe(u8, "John Doe"); // Default name
        }
        return try allocator.dupe(u8, input);
    } else {
        return try allocator.dupe(u8, "John Doe"); // Default name
    }
}

/// Background selection interface
fn backgroundSelection(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator) !character_mode.CharacterBackground {
    try ui.clear();
    try ui.drawTitle("Select Your Background");
    
    const backgrounds = [_]character_mode.CharacterBackground{
        .field_worker,
        .geologist,
        .engineer,
        .business_grad,
        .entrepreneur,
        .military,
    };
    
    for (backgrounds, 0..) |background, i| {
        try ui.print(try std.fmt.allocPrint(allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(background)}), .bright_cyan, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{background.getDescription()}), .white, .normal);
        
        // Show starting skills
        const starting_skills = background.getStartingSkills();
        try ui.print("   Starting Skills: ", .yellow, .italic);
        
        var skills_str = std.ArrayList(u8).init(allocator);
        defer skills_str.deinit();
        
        inline for (std.meta.tags(character_mode.SkillType), 0..) |skill_type, j| {
            if (starting_skills[j] > 0) {
                try std.fmt.format(skills_str.writer(), "{s} {d}, ", .{@tagName(skill_type), starting_skills[j]});
                try ui.print(skills_str.items, .bright_yellow, .normal);
                skills_str.clearRetainingCapacity();
            }
        }
        
        try ui.stdout.print("\n\n", .{});
    }
    
    try ui.stdout.print("Enter your choice (1-6): ", .{});
    
    var buf: [100]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
        const choice = std.fmt.parseInt(usize, input, 10) catch 1;
        if (choice > 0 and choice <= backgrounds.len) {
            return backgrounds[choice - 1];
        }
    }
    
    return .field_worker; // Default choice
}

/// Trait selection interface
fn traitSelection(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator) !character_mode.CharacterTrait {
    try ui.clear();
    try ui.drawTitle("Select Your Primary Trait");
    
    const traits = [_]character_mode.CharacterTrait{
        .ambitious,
        .cautious,
        .charismatic,
        .innovative,
        .methodical,
        .risk_taker,
    };
    
    for (traits, 0..) |trait, i| {
        try ui.print(try std.fmt.allocPrint(allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(trait)}), .bright_magenta, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{trait.getDescription()}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "   Effect: {s}", .{trait.getEffect()}), .yellow, .italic);
        try ui.stdout.print("\n", .{});
    }
    
    try ui.stdout.print("Enter your choice (1-6): ", .{});
    
    var buf: [100]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
        const choice = std.fmt.parseInt(usize, input, 10) catch 1;
        if (choice > 0 and choice <= traits.len) {
            return traits[choice - 1];
        }
    }
    
    return .ambitious; // Default choice
}

/// Train skills interface
fn trainSkills(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, game: *character_mode.CharacterMode) !void {
    try ui.clear();
    try ui.drawTitle("Train Your Skills");
    
    const skills = [_]character_mode.SkillType{
        .drilling,
        .geology,
        .engineering,
        .business,
        .leadership,
        .research,
    };
    
    // Training cost is based on current level
    for (skills, 0..) |skill_type, i| {
        const skill_index = @intFromEnum(skill_type);
        const skill = game.character.skills[skill_index];
        const training_cost = @as(f32, @floatFromInt(skill.level)) * 100.0;
        
        try ui.print(try std.fmt.allocPrint(allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
        try ui.print(try std.fmt.allocPrint(allocator, "{s}: ", .{@tagName(skill_type)}), .bright_cyan, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "Level {d}", .{skill.level}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "   Training Cost: ${d:.2}", .{training_cost}), .yellow, .italic);
        try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{skill_type.getDescription()}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "   Effect: {s}", .{skill_type.getEffectDescription()}), .bright_green, .italic);
        try ui.stdout.print("\n", .{});
    }
    
    try ui.print("Cash Available: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{game.character.money}), .bright_green, .bold);
    
    try ui.stdout.print("\nEnter skill to train (1-6) or 0 to cancel: ", .{});
    
    var buf: [100]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
        const choice = std.fmt.parseInt(usize, input, 10) catch 0;
        if (choice > 0 and choice <= skills.len) {
            const skill_type = skills[choice - 1];
            const skill_index = @intFromEnum(skill_type);
            const skill = &game.character.skills[skill_index];
            
            const training_cost = @as(f32, @floatFromInt(skill.level)) * 100.0;
            
            if (game.character.money >= training_cost) {
                game.character.money -= training_cost;
                
                // Training gives a significant XP boost
                const training_xp = skill.level * 50;
                const leveled_up = game.character.addSkillExperience(skill_type, training_xp);
                
                try ui.clear();
                try ui.drawTitle("Training Results");
                try ui.println(try std.fmt.allocPrint(allocator, "You've spent ${d:.2} training your {s} skill.", .{training_cost, @tagName(skill_type)}), .white, .normal);
                try ui.println(try std.fmt.allocPrint(allocator, "Gained {d} XP in this skill.", .{training_xp}), .bright_green, .bold);
                
                if (leveled_up) {
                    try ui.println(try std.fmt.allocPrint(allocator, "Congratulations! Your {s} skill is now level {d}!", .{@tagName(skill_type), skill.level}), .bright_cyan, .bold);
                }
                
                // Update quest progress
                try game.character.updateQuestProgress(.upgrade_skills, 1.0);
            } else {
                try ui.println("You don't have enough money for this training.", .bright_red, .bold);
            }
            
            try ui.stdout.print("\nPress Enter to continue...", .{});
            _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
        }
    }
}

/// View skill details
fn viewSkillDetails(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, game: *character_mode.CharacterMode) !void {
    try ui.clear();
    try ui.drawTitle("Skill Details");
    
    for (game.character.skills) |skill| {
        try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(skill.skill_type)}), .bright_cyan, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{skill.skill_type.getDescription()}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "   Level: {d}", .{skill.level}), .bright_white, .bold);
        
        const modifier = game.character.getSkillModifier(skill.skill_type);
        try ui.println(try std.fmt.allocPrint(allocator, "   Current Effect: {d:.0}% {s}", 
            .{(modifier - 1.0) * 100.0, skill.skill_type.getEffectDescription()}), .bright_green, .normal);
        
        const points_to_next = skill.pointsToNextLevel();
        try ui.print("   Progress to Next Level: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d}/{d} XP", .{skill.experience_points, points_to_next}), .bright_yellow, .normal);
        
        const progress = skill.getLevelProgress();
        try ui.drawStatusBar("   ", try std.fmt.allocPrint(allocator, "{d:.1}%", .{progress * 100.0}), 20, '#', '-', progress, .bright_green);
        
        try ui.stdout.print("\n", .{});
    }
    
    try ui.println("Skills can be improved through:", .bright_white, .bold);
    try ui.println("* Daily activities (small XP gain)", .white, .normal);
    try ui.println("* Focused training (faster but costs money)", .white, .normal);
    try ui.println("* Completing related quests", .white, .normal);
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
}

/// View completed quests
fn viewCompletedQuests(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, game: *character_mode.CharacterMode) !void {
    try ui.clear();
    try ui.drawTitle("Completed Quests");
    
    if (game.character.completed_quests.items.len == 0) {
        try ui.println("You haven't completed any quests yet.", .yellow, .italic);
    } else {
        for (game.character.completed_quests.items, 0..) |quest, i| {
            try ui.print(try std.fmt.allocPrint(allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
            try ui.println(quest.title, .bright_green, .bold);
            try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{quest.description}), .white, .normal);
            try ui.println(try std.fmt.allocPrint(allocator, "   Rewards: {d} XP, ${d:.2}", .{quest.reward_xp, quest.reward_money}), .bright_yellow, .normal);
            try ui.stdout.print("\n", .{});
        }
    }
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
} 