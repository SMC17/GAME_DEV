const std = @import("std");
const oil_field = @import("engine/oil_field.zig");
const simulation = @import("engine/simulation.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var sim = try simulation.SimulationEngine.init(allocator);
    defer sim.deinit();
    
    // Create some oil fields
    const small_field = oil_field.OilField.init(1000.0, 5.0);
    const medium_field = oil_field.OilField.init(5000.0, 10.0);
    const large_field = oil_field.OilField.init(10000.0, 15.0);
    
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
}

// Helper function to create a range for iteration
fn range(start: usize, end: usize) []const void {
    _ = start;
    _ = end;
    return &[_]void{};
} 