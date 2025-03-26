const std = @import("std");
const campaign_mode = @import("campaign_mode.zig");
const narrative = @import("narrative.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var stdout = std.io.getStdOut().writer();
    
    try stdout.print("=== TURMOIL: Campaign Mode ===\n\n", .{});
    try stdout.print("Welcome to the oil business! Let's start your journey.\n\n", .{});
    
    // Create campaign
    var campaign = try campaign_mode.CampaignMode.init(allocator, "John Smith", "Smith Oil Co.");
    defer campaign.deinit();
    
    // Initialize narrative manager
    var narrative_mgr = narrative.NarrativeManager.init(allocator);
    defer narrative_mgr.deinit();
    
    // Add sample story events
    const intro_dialogues = [_]narrative.Dialogue{
        .{
            .character = "Advisor",
            .text = "Welcome to the oil business, boss! We've secured our first small oil field. It's not much, but it's a start.",
            .choices = null,
        },
        .{
            .character = "You",
            .text = "We'll make it work. Let's start drilling and see what we can do.",
            .choices = null,
        },
    };
    
    const intro_event = narrative.StoryEvent{
        .id = 1,
        .title = "The Beginning",
        .description = "Your journey into the oil business begins.",
        .dialogues = &intro_dialogues,
        .trigger_condition = narrative.TriggerCondition{ .game_day = 1 },
        .has_occurred = false,
    };
    
    try narrative_mgr.addStoryEvent(intro_event);
    
    // Start the game loop
    while (true) {
        // Display current mission
        if (campaign.getCurrentMission()) |mission| {
            try stdout.print("Current Mission: {s}\n", .{mission.title});
            try stdout.print("  {s}\n\n", .{mission.description});
        }
        
        // Display company status
        try stdout.print("Day {d}: {s}\n", .{campaign.game_days + 1, campaign.company_name});
        try stdout.print("  Cash: ${d:.2}\n", .{campaign.simulation.money});
        try stdout.print("  Total Oil Extracted: {d:.2} barrels\n", .{campaign.simulation.total_extracted});
        try stdout.print("  Current Oil Price: ${d:.2}\n", .{campaign.simulation.oil_price});
        try stdout.print("  Oil Fields: {d}\n\n", .{campaign.simulation.oil_fields.items.len});
        
        // Check for narrative events
        if (narrative_mgr.checkTriggers(
            campaign.current_mission_id,
            campaign.simulation.money,
            campaign.simulation.total_extracted,
            campaign.game_days
        )) |event| {
            try stdout.print("=== {s} ===\n", .{event.title});
            try stdout.print("{s}\n\n", .{event.description});
            
            for (event.dialogues) |dialogue| {
                try stdout.print("{s}: {s}\n", .{dialogue.character, dialogue.text});
            }
            try stdout.print("\n", .{});
        }
        
        // Prompt for action
        try stdout.print("Options:\n", .{});
        try stdout.print("  1. Advance to next day\n", .{});
        try stdout.print("  2. View oil fields\n", .{});
        try stdout.print("  3. Quit\n", .{});
        try stdout.print("Enter choice (1-3): ", .{});
        
        // Simulate user input for this demo
        const choice: u8 = 1;
        try stdout.print("1\n\n", .{}); // Always choose to advance day for this demo
        
        if (choice == 1) {
            // Advance day
            try campaign.advanceDay();
            
            // Check mission completion
            if (campaign.getCurrentMission()) |mission| {
                if (mission.completed) {
                    try stdout.print("Mission Completed: {s}!\n\n", .{mission.title});
                }
            }
            
            // End demo after 10 days
            if (campaign.game_days >= 10) {
                try stdout.print("=== Demo Complete ===\n", .{});
                try stdout.print("Thank you for playing the TURMOIL campaign mode demo!\n", .{});
                try stdout.print("The full game will feature many more missions, story events, and gameplay mechanics.\n", .{});
                break;
            }
        } else if (choice == 2) {
            // View oil fields
            try stdout.print("Oil Fields:\n", .{});
            for (campaign.simulation.oil_fields.items, 0..) |field, i| {
                try stdout.print("  Field {d}: {d:.2}% full, extracting {d:.2} barrels/day\n", 
                    .{i + 1, field.getPercentageFull() * 100, field.extraction_rate * field.quality});
            }
            try stdout.print("\n", .{});
        } else if (choice == 3) {
            break;
        }
    }
} 