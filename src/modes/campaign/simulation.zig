const std = @import("std");
const oil_field = @import("oil_field.zig");

/// The main simulation engine for the game
pub const SimulationEngine = struct {
    oil_fields: std.ArrayList(oil_field.OilField),
    total_extracted: f32,
    money: f32,
    time_elapsed: f32,
    oil_price: f32,
    allocator: std.mem.Allocator,
    
    /// Initialize a new simulation engine
    pub fn init(allocator: std.mem.Allocator) !SimulationEngine {
        return SimulationEngine{
            .oil_fields = std.ArrayList(oil_field.OilField).init(allocator),
            .total_extracted = 0,
            .money = 10000, // Starting capital
            .time_elapsed = 0,
            .oil_price = 50, // Default price per barrel
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *SimulationEngine) void {
        self.oil_fields.deinit();
    }
    
    /// Add a new oil field to the simulation
    pub fn addOilField(self: *SimulationEngine, field: oil_field.OilField) !void {
        try self.oil_fields.append(field);
    }
    
    /// Run a simulation step with the given time delta
    pub fn step(self: *SimulationEngine, delta: f32) !void {
        self.time_elapsed += delta;
        
        var total_extracted_this_step: f32 = 0;
        
        for (self.oil_fields.items) |*field| {
            const extracted = field.extract(delta);
            total_extracted_this_step += extracted;
        }
        
        self.total_extracted += total_extracted_this_step;
        self.money += total_extracted_this_step * self.oil_price;
        
        // Simplified market fluctuation without random number generation
        // Use a simple sine wave based on time for now
        const price_change = @sin(self.time_elapsed * 0.1) * 2.0; // -2 to +2 dollars
        self.oil_price += price_change;
        
        // Keep price in reasonable range
        if (self.oil_price < 20) self.oil_price = 20;
        if (self.oil_price > 100) self.oil_price = 100;
    }
}; 