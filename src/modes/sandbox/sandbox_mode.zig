const std = @import("std");
const base_oil_field = @import("../../engine/oil_field.zig");
const base_simulation = @import("../../engine/simulation.zig");

/// Customizable oil field for sandbox mode
pub const SandboxOilField = struct {
    base: base_oil_field.OilField,
    custom_name: []const u8,
    discovery_date: u32, // Game day when discovered
    custom_notes: ?[]const u8, // Optional notes about this field
    
    /// Initialize a new sandbox oil field
    pub fn init(allocator: std.mem.Allocator, name: []const u8, size: f32, extraction_rate: f32, quality: f32, depth: f32) !SandboxOilField {
        var base_field = base_oil_field.OilField.init(size, extraction_rate);
        base_field.quality = quality;
        base_field.depth = depth;
        
        const field_name = try allocator.dupe(u8, name);
        
        return SandboxOilField{
            .base = base_field,
            .custom_name = field_name,
            .discovery_date = 0,
            .custom_notes = null,
        };
    }
    
    /// Set custom notes for this field
    pub fn setNotes(self: *SandboxOilField, allocator: std.mem.Allocator, notes: []const u8) !void {
        if (self.custom_notes) |old_notes| {
            allocator.free(old_notes);
        }
        
        self.custom_notes = try allocator.dupe(u8, notes);
    }
    
    /// Clean up resources
    pub fn deinit(self: *SandboxOilField, allocator: std.mem.Allocator) void {
        allocator.free(self.custom_name);
        if (self.custom_notes) |notes| {
            allocator.free(notes);
        }
    }
};

/// Market scenario preset for the sandbox
pub const MarketScenario = enum {
    stable,
    boom,
    bust,
    volatile,
    shortage,
    oversupply,
    
    /// Get the base oil price for this scenario
    pub fn getBasePrice(self: MarketScenario) f32 {
        return switch (self) {
            .stable => 50.0,
            .boom => 80.0,
            .bust => 30.0,
            .volatile => 60.0,
            .shortage => 90.0,
            .oversupply => 25.0,
        };
    }
    
    /// Get the price volatility for this scenario
    pub fn getVolatility(self: MarketScenario) f32 {
        return switch (self) {
            .stable => 0.05, // 5% max change
            .boom => 0.1,    // 10% max change
            .bust => 0.1,    // 10% max change
            .volatile => 0.25, // 25% max change
            .shortage => 0.15, // 15% max change
            .oversupply => 0.08, // 8% max change
        };
    }
    
    /// Get the demand factor for this scenario
    pub fn getDemandFactor(self: MarketScenario) f32 {
        return switch (self) {
            .stable => 1.0,
            .boom => 1.3,
            .bust => 0.7,
            .volatile => 1.0,
            .shortage => 1.2,
            .oversupply => 0.8,
        };
    }
    
    /// Get the description for this scenario
    pub fn getDescription(self: MarketScenario) []const u8 {
        return switch (self) {
            .stable => "Steady prices with minimal fluctuations",
            .boom => "High prices with upward pressure",
            .bust => "Low prices with downward pressure",
            .volatile => "Unpredictable price swings in both directions",
            .shortage => "Supply constraints driving prices higher",
            .oversupply => "Excess production depressing prices",
        };
    }
};

/// Environmental factors for simulation
pub const EnvironmentalFactors = struct {
    disaster_chance: f32, // Chance of environmental disaster per day
    regulatory_pressure: f32, // 0.0 to 1.0, affects costs and restrictions
    public_opinion: f32, // 0.0 to 1.0, affects reputation and operations
    cleanup_cost_multiplier: f32, // Multiplier for cleanup costs
    
    /// Initialize with default parameters
    pub fn init() EnvironmentalFactors {
        return EnvironmentalFactors{
            .disaster_chance = 0.001, // 0.1% chance per day
            .regulatory_pressure = 0.5, // Moderate regulations
            .public_opinion = 0.5, // Neutral public opinion
            .cleanup_cost_multiplier = 1.0,
        };
    }
    
    /// Get the operational cost multiplier based on environmental factors
    pub fn getOperationalCostMultiplier(self: *const EnvironmentalFactors) f32 {
        return 1.0 + (self.regulatory_pressure * 0.5);
    }
    
    /// Check if an environmental disaster occurs
    pub fn checkDisaster(self: *const EnvironmentalFactors, day: u32) bool {
        // Use day as a simple RNG source for deterministic results
        const day_factor = @mod(day, 1000) / 1000.0;
        return day_factor < self.disaster_chance;
    }
    
    /// Calculate cleanup cost for a disaster
    pub fn calculateCleanupCost(self: *const EnvironmentalFactors, field_size: f32) f32 {
        return field_size * 5.0 * self.cleanup_cost_multiplier;
    }
    
    /// Calculate reputation damage from a disaster
    pub fn calculateReputationDamage(self: *const EnvironmentalFactors) f32 {
        return 0.1 + (self.public_opinion * 0.1); // 0.1 to 0.2 reputation loss
    }
};

/// Structure representing sandbox mode
pub const SandboxMode = struct {
    oil_fields: std.ArrayList(SandboxOilField),
    simulation: base_simulation.SimulationEngine,
    current_day: u32,
    time_scale: f32, // How many days per step
    auto_run: bool, // If true, automatically advance time
    market_scenario: MarketScenario,
    environmental_factors: EnvironmentalFactors,
    disaster_history: std.ArrayList(DisasterEvent),
    price_history: std.ArrayList(PricePoint),
    production_history: std.ArrayList(ProductionPoint),
    allocator: std.mem.Allocator,
    
    /// Initialize a new sandbox mode
    pub fn init(allocator: std.mem.Allocator) !SandboxMode {
        var simulation = try base_simulation.SimulationEngine.init(allocator);
        
        return SandboxMode{
            .oil_fields = std.ArrayList(SandboxOilField).init(allocator),
            .simulation = simulation,
            .current_day = 1,
            .time_scale = 1.0,
            .auto_run = false,
            .market_scenario = .stable,
            .environmental_factors = EnvironmentalFactors.init(),
            .disaster_history = std.ArrayList(DisasterEvent).init(allocator),
            .price_history = std.ArrayList(PricePoint).init(allocator),
            .production_history = std.ArrayList(ProductionPoint).init(allocator),
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *SandboxMode) void {
        for (self.oil_fields.items) |*field| {
            field.deinit(self.allocator);
        }
        self.oil_fields.deinit();
        self.simulation.deinit();
        self.disaster_history.deinit();
        self.price_history.deinit();
        self.production_history.deinit();
    }
    
    /// Set the market scenario
    pub fn setMarketScenario(self: *SandboxMode, scenario: MarketScenario) void {
        self.market_scenario = scenario;
        self.simulation.oil_price = scenario.getBasePrice();
    }
    
    /// Create and add a new oil field
    pub fn addOilField(self: *SandboxMode, name: []const u8, size: f32, extraction_rate: f32, quality: f32, depth: f32) !void {
        var sandbox_field = try SandboxOilField.init(self.allocator, name, size, extraction_rate, quality, depth);
        sandbox_field.discovery_date = self.current_day;
        
        try self.oil_fields.append(sandbox_field);
        try self.simulation.addOilField(sandbox_field.base);
    }
    
    /// Update oil price based on market scenario and day
    fn updateOilPrice(self: *SandboxMode) void {
        const base_price = self.market_scenario.getBasePrice();
        const volatility = self.market_scenario.getVolatility();
        
        // Use day as a simple pseudorandom source
        const day_sin = @sin(@as(f32, @floatFromInt(self.current_day)) * 0.1);
        const day_cos = @cos(@as(f32, @floatFromInt(self.current_day)) * 0.05);
        const random_factor = (day_sin + day_cos) * volatility;
        
        self.simulation.oil_price = base_price * (1.0 + random_factor);
        
        // Record price history (every 10 days to save memory)
        if (self.current_day % 10 == 0) {
            try self.price_history.append(PricePoint{
                .day = self.current_day,
                .price = self.simulation.oil_price,
            });
        }
    }
    
    /// Check for and handle environmental disasters
    fn checkEnvironmentalDisasters(self: *SandboxMode) !void {
        if (self.environmental_factors.checkDisaster(self.current_day)) {
            // Choose a random field for the disaster
            if (self.oil_fields.items.len > 0) {
                const field_index = @mod(self.current_day, self.oil_fields.items.len);
                var field = &self.oil_fields.items[field_index];
                
                // Calculate impact
                const cleanup_cost = self.environmental_factors.calculateCleanupCost(field.base.max_capacity);
                const reputation_damage = self.environmental_factors.calculateReputationDamage();
                
                // Apply costs
                self.simulation.money -= cleanup_cost;
                
                // Record the disaster
                try self.disaster_history.append(DisasterEvent{
                    .day = self.current_day,
                    .field_name = field.custom_name,
                    .cleanup_cost = cleanup_cost,
                    .reputation_damage = reputation_damage,
                });
            }
        }
    }
    
    /// Advance the simulation by one step
    pub fn advanceSimulation(self: *SandboxMode) !void {
        // Record production before the step
        if (self.current_day % 10 == 0) {
            var total_production: f32 = 0.0;
            for (self.simulation.oil_fields.items) |field| {
                total_production += field.extraction_rate * field.quality;
            }
            
            try self.production_history.append(ProductionPoint{
                .day = self.current_day,
                .production_rate = total_production,
                .total_extracted = self.simulation.total_extracted,
            });
        }
        
        // Apply time scale
        var i: f32 = 0.0;
        while (i < self.time_scale) : (i += 1.0) {
            try self.simulation.step(1.0);
            self.current_day += 1;
            
            // Update price based on market conditions
            try self.updateOilPrice();
            
            // Check for environmental disasters
            try self.checkEnvironmentalDisasters();
        }
    }
    
    /// Set environmental factors
    pub fn setEnvironmentalFactors(self: *SandboxMode, disaster_chance: f32, regulatory_pressure: f32, public_opinion: f32) void {
        self.environmental_factors.disaster_chance = disaster_chance;
        self.environmental_factors.regulatory_pressure = regulatory_pressure;
        self.environmental_factors.public_opinion = public_opinion;
        
        // Update cost multiplier based on regulatory pressure
        const env_multiplier = self.environmental_factors.getOperationalCostMultiplier();
    }
    
    /// Generate a report of the current state
    pub fn generateReport(self: *SandboxMode, allocator: std.mem.Allocator) ![]const u8 {
        var report = std.ArrayList(u8).init(allocator);
        defer report.deinit();
        
        var writer = report.writer();
        
        try writer.print("=== Sandbox Simulation Report (Day {d}) ===\n\n", .{self.current_day});
        
        // Financial summary
        try writer.print("Financial Summary:\n", .{});
        try writer.print("  Total Money: ${d:.2}\n", .{self.simulation.money});
        try writer.print("  Current Oil Price: ${d:.2} per barrel\n", .{self.simulation.oil_price});
        try writer.print("  Total Oil Extracted: {d:.2} barrels\n\n", .{self.simulation.total_extracted});
        
        // Oil Fields
        try writer.print("Oil Fields ({d}):\n", .{self.oil_fields.items.len});
        for (self.oil_fields.items, 0..) |field, i| {
            try writer.print("  {d}. {s}\n", .{i + 1, field.custom_name});
            try writer.print("     Size: {d:.2} barrels ({d:.1}% remaining)\n", 
                .{field.base.max_capacity, field.base.getPercentageFull() * 100.0});
            try writer.print("     Extraction Rate: {d:.2} barrels/day\n", .{field.base.extraction_rate * field.base.quality});
            try writer.print("     Discovered: Day {d}\n", .{field.discovery_date});
            if (field.custom_notes) |notes| {
                try writer.print("     Notes: {s}\n", .{notes});
            }
            try writer.print("\n", .{});
        }
        
        // Environmental
        try writer.print("Environmental Factors:\n", .{});
        try writer.print("  Disaster Chance: {d:.3}%\n", .{self.environmental_factors.disaster_chance * 100.0});
        try writer.print("  Regulatory Pressure: {d:.1}%\n", .{self.environmental_factors.regulatory_pressure * 100.0});
        try writer.print("  Public Opinion: {d:.1}%\n\n", .{self.environmental_factors.public_opinion * 100.0});
        
        // Disaster History
        if (self.disaster_history.items.len > 0) {
            try writer.print("Disaster History:\n", .{});
            for (self.disaster_history.items) |disaster| {
                try writer.print("  Day {d}: Disaster at {s}\n", .{disaster.day, disaster.field_name});
                try writer.print("     Cleanup Cost: ${d:.2}\n", .{disaster.cleanup_cost});
                try writer.print("     Reputation Damage: {d:.1}%\n", .{disaster.reputation_damage * 100.0});
            }
            try writer.print("\n", .{});
        }
        
        // Recent Price History (last 5 entries)
        if (self.price_history.items.len > 0) {
            try writer.print("Recent Price History:\n", .{});
            const start = if (self.price_history.items.len > 5) self.price_history.items.len - 5 else 0;
            for (self.price_history.items[start..]) |price_point| {
                try writer.print("  Day {d}: ${d:.2}\n", .{price_point.day, price_point.price});
            }
        }
        
        return try report.toOwnedSlice();
    }
};

/// Structure representing an environmental disaster event
pub const DisasterEvent = struct {
    day: u32,
    field_name: []const u8,
    cleanup_cost: f32,
    reputation_damage: f32,
};

/// Structure for recording oil price history
pub const PricePoint = struct {
    day: u32,
    price: f32,
};

/// Structure for recording production history
pub const ProductionPoint = struct {
    day: u32,
    production_rate: f32,
    total_extracted: f32,
}; 