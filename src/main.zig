const std = @import("std");
const oil_field = @import("engine/oil_field.zig");
const simulation = @import("engine/simulation.zig");
const main_menu = @import("main_menu.zig");
const player_data = @import("shared/player_data.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Launch the main menu with player data integration
    var menu = try main_menu.MainMenu.init(allocator);
    defer menu.deinit();
    
    try menu.run();
}

// This is the original simulation demo, kept as a reference
pub fn runSimulationDemo(allocator: std.mem.Allocator) !void {
    var sim = try simulation.SimulationEngine.init(allocator);
    defer sim.deinit();
    
    // Create some oil fields
    var small_field = try oil_field.OilField.init(
        allocator,
        1000.0, // capacity
        5.0,    // extraction rate
        1.0     // quality
    );
    
    var medium_field = try oil_field.OilField.init(
        allocator,
        5000.0, // capacity
        10.0,   // extraction rate
        0.9     // quality
    );
    
    var large_field = try oil_field.OilField.init(
        allocator,
        10000.0, // capacity
        15.0,    // extraction rate
        0.8      // quality
    );
    
    try sim.addOilField(small_field);
    try sim.addOilField(medium_field);
    try sim.addOilField(large_field);
    
    var stdout = std.io.getStdOut().writer();
    
    try stdout.print("=== TURMOIL: Oil Industry Simulation ===\n\n", .{});
    
    // Run simulation for 10 cycles
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try sim.step(1.0);
        
        try stdout.print("Day {d}:\n", .{i + 1});
        try stdout.print("  Total Oil Extracted: {d:.2} barrels\n", .{sim.total_extracted});
        try stdout.print("  Current Oil Price: ${d:.2}\n", .{sim.oil_price});
        try stdout.print("  Company Value: ${d:.2}\n", .{sim.money});
        try stdout.print("  Oil Fields Status:\n", .{});
        
        for (sim.oil_fields.items, 0..) |field, field_idx| {
            try stdout.print("    Field {d}: {d:.2}% full, extracting {d:.2} barrels/day\n", 
                .{field_idx + 1, field.getPercentageFull() * 100, field.extraction_rate * field.quality});
        }
        
        try stdout.print("\n", .{});
    }
    
    try stdout.print("=== Simulation Complete ===\n", .{});
    
    // If we have player data, record an achievement for running the simulation
    if (player_data.getGlobalPlayerData()) |data| {
        try data.unlockAchievement("ran_simulation_demo");
        _ = player_data.saveGlobalPlayerData() catch {};
    }
}

// Helper function to create a range for iteration
fn range(start: usize, end: usize) []const void {
    _ = start;
    _ = end;
    return &[_]void{};
} 