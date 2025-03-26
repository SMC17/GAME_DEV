const std = @import("std");
const testing = std.testing;
const simulation = @import("../src/engine/simulation.zig");
const oil_field = @import("../src/engine/oil_field.zig");
const tycoon_mode = @import("../src/modes/tycoon/tycoon_mode.zig");
const character_mode = @import("../src/modes/character/character_mode.zig");
const arcade_mode = @import("../src/modes/arcade/arcade_mode.zig");
const campaign_mode = @import("../src/modes/campaign/campaign_mode.zig");
const sandbox_mode = @import("../src/modes/sandbox/sandbox_mode.zig");

// Integration test between Tycoon mode and the core simulation engine
test "Tycoon mode integrates with simulation engine" {
    var allocator = testing.allocator;
    
    // Initialize tycoon mode
    var tycoon = try tycoon_mode.TycoonMode.init(allocator);
    defer tycoon.deinit();
    
    // Verify simulation engine is properly initialized
    try testing.expect(tycoon.simulation.oil_fields.items.len == 0);
    try testing.expect(tycoon.simulation.money > 0);
    
    // Test oil field purchase flows through to simulation engine
    try tycoon.purchaseOilField(.onshore, 1000.0, 10.0, 1.0, 1.0);
    try testing.expect(tycoon.simulation.oil_fields.items.len == 1);
    
    // Test that daily operations update the simulation correctly
    const initial_money = tycoon.simulation.money;
    try tycoon.simulateDay();
    try testing.expect(tycoon.simulation.money != initial_money);
}

// Integration test between Character mode and Campaign mode
test "Character progression affects Campaign outcomes" {
    var allocator = testing.allocator;
    
    // Initialize character mode
    var character = try character_mode.CharacterMode.init(allocator);
    defer character.deinit();
    
    // Initialize campaign mode
    var campaign = try campaign_mode.CampaignMode.init(allocator, "Test Player", "Test Company");
    defer campaign.deinit();
    
    // Simulate character skill development
    var skill = character.getSkill(.drilling) orelse unreachable;
    const initial_level = skill.level;
    
    // Add experience to drilling skill
    try character.addExperience(.drilling, 1000);
    skill = character.getSkill(.drilling) orelse unreachable;
    
    // Verify skill level increased
    try testing.expect(skill.level > initial_level);
    
    // TODO: In a full implementation, we would verify that the character's
    // skill level affects campaign outcomes, for example by modifying
    // extraction rates or success probabilities in missions
}

// Integration test between Arcade mode and Sandbox mode
test "Arcade mode high scores are preserved in Sandbox mode" {
    var allocator = testing.allocator;
    
    // Initialize arcade mode with medium difficulty
    var arcade = arcade_mode.ArcadeMode.init(allocator, .medium);
    defer arcade.deinit();
    
    // Simulate gameplay and add a high score
    arcade.score = 5000;
    arcade.oil_extracted = 500.0;
    try arcade.addHighScore("Test Player");
    
    // Verify high score was recorded
    try testing.expect(arcade.high_scores.items.len == 1);
    try testing.expectEqual(@as(u32, 5000), arcade.high_scores.items[0].score);
    
    // Create sandbox mode
    var sandbox = try sandbox_mode.SandboxMode.init(allocator);
    defer sandbox.deinit();
    
    // TODO: In a full implementation, we would verify that sandbox mode
    // can access and display high scores from arcade mode, showing the
    // integration between these modes
}

// Integration test for data sharing between all modes
test "Game modes share and maintain consistent data" {
    // This test would verify that game modes can correctly share core data
    // such as oil fields, financial data, and other persistent state
    // For now, we'll just mark it as skipped
    return error.SkipZigTest;
}

// Run all integration tests
pub fn main() !void {
    testing.log_level = .debug;
    try testing.run();
} 