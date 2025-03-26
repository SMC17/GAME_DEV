const std = @import("std");
const arcade_mode = @import("arcade_mode.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var stdout = std.io.getStdOut().writer();
    
    try stdout.print("=== TURMOIL: Arcade Mode ===\n\n", .{});
    try stdout.print("Welcome to the fast-paced world of arcade oil drilling!\n\n", .{});
    
    // Print difficulty options
    try stdout.print("Select difficulty:\n", .{});
    try stdout.print("  1. Easy (120 seconds, 1.0x score multiplier)\n", .{});
    try stdout.print("  2. Medium (90 seconds, 1.5x score multiplier)\n", .{});
    try stdout.print("  3. Hard (60 seconds, 2.0x score multiplier)\n", .{});
    
    // Simulate user selecting medium difficulty
    try stdout.print("Selected: 2\n\n", .{});
    const difficulty = arcade_mode.DifficultyLevel.medium;
    
    // Create arcade game
    var game = arcade_mode.ArcadeMode.init(allocator, difficulty);
    defer game.deinit();
    
    try stdout.print("=== Game Starting ===\n", .{});
    try stdout.print("Difficulty: Medium\n", .{});
    try stdout.print("Time Limit: {d} seconds\n", .{game.time_remaining});
    try stdout.print("Oil Field Size: {d} barrels\n\n", .{game.oil_field.max_capacity});
    
    // Simulated frame rate (for simulation purposes)
    const frame_rate = 10; // 10 updates per second for this demo
    const delta_time = 1.0 / @as(f32, @floatFromInt(frame_rate));
    
    // Game loop - simulate 20 inputs
    var i: usize = 0;
    while (i < 20 and !game.isGameOver()) : (i += 1) {
        // Update game state
        game.update(delta_time);
        
        // Display game status
        try stdout.print("Time Remaining: {d:.1}s | Score: {d} | Combo: {d:.1}x\n", 
            .{game.time_remaining, game.score, game.combo_multiplier});
        
        // Simulate player input
        // In a real game, we would get input from keyboard/gamepad
        const power_level = @mod(i, 3); // 0, 1, or 2
        const extraction_power = 1.0 + @as(f32, @floatFromInt(power_level)) * 0.5;
        try stdout.print("Drilling with power: {d:.1}\n", .{extraction_power});
        
        // Extract oil based on simulated input
        game.extractOil(extraction_power);
        
        // Display extraction result
        try stdout.print("Oil Field: {d:.1}% remaining | Total Extracted: {d:.1} barrels\n\n", 
            .{game.oil_field.getPercentageFull() * 100, game.oil_extracted});
        
        // Pause between frames (only in simulation)
        // In a real-time game, this would be handled by the game loop timing
        std.time.sleep(100 * std.time.ns_per_ms);
    }
    
    // Game over
    try stdout.print("=== Game Over ===\n", .{});
    try stdout.print("Final Score: {d}\n", .{game.score});
    try stdout.print("Oil Extracted: {d:.1} barrels\n", .{game.oil_extracted});
    try stdout.print("Time Remaining: {d:.1} seconds\n\n", .{game.time_remaining});
    
    // Add to high scores
    try game.addHighScore("Player 1");
    
    // Display high scores
    try stdout.print("=== High Scores ===\n", .{});
    for (game.high_scores.items, 0..) |high_score, index| {
        try stdout.print("{d}. {s}: {d} points ({d:.1} barrels, {s})\n", 
            .{index + 1, high_score.player_name, high_score.score, high_score.oil_extracted, @tagName(high_score.difficulty)});
    }
} 