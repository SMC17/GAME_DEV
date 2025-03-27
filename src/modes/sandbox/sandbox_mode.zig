const std = @import("std");
const base_oil_field = @import("../../engine/oil_field.zig");
const base_simulation = @import("../../engine/simulation.zig");
const player_data = @import("../../shared/player_data.zig");

/// Weather conditions that can affect oil operations
pub const WeatherCondition = enum {
    clear,
    cloudy,
    rainy,
    stormy,
    blizzard,
    heatwave,
    
    /// Get description of the weather condition
    pub fn getDescription(self: WeatherCondition) []const u8 {
        return switch (self) {
            .clear => "Clear skies with ideal working conditions",
            .cloudy => "Overcast but operations running normally",
            .rainy => "Rainy conditions causing minor delays",
            .stormy => "Storm conditions limiting operations",
            .blizzard => "Blizzard conditions severely impacting operations",
            .heatwave => "Extreme heat causing equipment strain and worker fatigue",
        };
    }
    
    /// Get production multiplier based on weather condition
    pub fn getProductionMultiplier(self: WeatherCondition) f32 {
        return switch (self) {
            .clear => 1.1,     // Slight bonus in good weather
            .cloudy => 1.0,    // No effect
            .rainy => 0.85,    // 15% reduction
            .stormy => 0.6,    // 40% reduction
            .blizzard => 0.3,  // 70% reduction
            .heatwave => 0.75, // 25% reduction
        };
    }
    
    /// Get operational cost multiplier
    pub fn getOperationalCostMultiplier(self: WeatherCondition) f32 {
        return switch (self) {
            .clear => 0.95,    // 5% cost reduction
            .cloudy => 1.0,    // No effect
            .rainy => 1.1,     // 10% increase
            .stormy => 1.3,    // 30% increase
            .blizzard => 1.5,  // 50% increase
            .heatwave => 1.2,  // 20% increase
        };
    }
    
    /// Get risk of incidents (affects disaster chance)
    pub fn getIncidentRiskMultiplier(self: WeatherCondition) f32 {
        return switch (self) {
            .clear => 0.8,     // 20% less incidents
            .cloudy => 1.0,    // No effect
            .rainy => 1.2,     // 20% more incidents
            .stormy => 2.0,    // Double incidents
            .blizzard => 2.5,  // 150% more incidents
            .heatwave => 1.5,  // 50% more incidents
        };
    }
};

/// Region type that affects weather patterns
pub const RegionType = enum {
    temperate,
    desert,
    tropical,
    arctic,
    offshore,
    
    /// Get description of the region
    pub fn getDescription(self: RegionType) []const u8 {
        return switch (self) {
            .temperate => "Moderate climate with seasonal changes",
            .desert => "Hot, dry climate with extreme temperature variations",
            .tropical => "Hot, humid climate with frequent rainfall",
            .arctic => "Cold climate with harsh winters",
            .offshore => "Marine environment subject to sea conditions",
        };
    }
    
    /// Get probability distribution for weather conditions based on region
    pub fn getWeatherProbabilities(self: RegionType) [6]f32 {
        return switch (self) {
            .temperate => [6]f32{ 0.5, 0.25, 0.15, 0.07, 0.01, 0.02 }, // More clear days
            .desert => [6]f32{ 0.7, 0.15, 0.03, 0.02, 0.0, 0.1 },      // Mostly clear, some heatwaves
            .tropical => [6]f32{ 0.25, 0.2, 0.3, 0.2, 0.0, 0.05 },     // More rain and storms
            .arctic => [6]f32{ 0.3, 0.2, 0.1, 0.15, 0.25, 0.0 },       // More blizzards
            .offshore => [6]f32{ 0.3, 0.25, 0.2, 0.2, 0.05, 0.0 },     // More storms
        };
    }
    
    /// Generate weather condition based on day and region
    pub fn generateWeather(self: RegionType, day: u32) WeatherCondition {
        // Use day as pseudo-random source for deterministic weather
        var probs = self.getWeatherProbabilities();
        var day_value = @mod(day * day, 1000) / 1000.0;
        
        // Convert day value to weather condition based on probability thresholds
        var cumulative: f32 = 0.0;
        for (probs, 0..) |prob, i| {
            cumulative += prob;
            if (day_value < cumulative) {
                return @enumFromInt(i);
            }
        }
        return .clear; // Default to clear if something goes wrong
    }
};

/// Weather system for sandbox mode
pub const WeatherSystem = struct {
    region_type: RegionType,
    current_condition: WeatherCondition,
    forecast: [7]WeatherCondition, // Weather for next 7 days
    
    /// Initialize a new weather system
    pub fn init(region: RegionType, start_day: u32) WeatherSystem {
        var system = WeatherSystem{
            .region_type = region,
            .current_condition = region.generateWeather(start_day),
            .forecast = undefined,
        };
        
        // Generate forecast for next 7 days
        for (0..7) |i| {
            system.forecast[i] = region.generateWeather(start_day + @as(u32, @intCast(i)) + 1);
        }
        
        return system;
    }
    
    /// Update weather for a new day
    pub fn updateForDay(self: *WeatherSystem, day: u32) void {
        self.current_condition = self.forecast[0];
        
        // Shift forecast
        for (1..7) |i| {
            self.forecast[i-1] = self.forecast[i];
        }
        
        // Generate new weather for last forecast day
        self.forecast[6] = self.region_type.generateWeather(day + 7);
    }
    
    /// Get the current production multiplier
    pub fn getCurrentProductionMultiplier(self: WeatherSystem) f32 {
        return self.current_condition.getProductionMultiplier();
    }
    
    /// Get the current cost multiplier
    pub fn getCurrentCostMultiplier(self: WeatherSystem) f32 {
        return self.current_condition.getOperationalCostMultiplier();
    }
    
    /// Get the current incident risk multiplier
    pub fn getCurrentIncidentRiskMultiplier(self: WeatherSystem) f32 {
        return self.current_condition.getIncidentRiskMultiplier();
    }
    
    /// Generate a weather report
    pub fn generateReport(self: WeatherSystem, allocator: std.mem.Allocator) ![]const u8 {
        var report = std.ArrayList(u8).init(allocator);
        defer report.deinit();
        
        var writer = report.writer();
        
        try writer.print("WEATHER REPORT - {s} REGION\n", .{self.region_type.getDescription()});
        try writer.print("Current conditions: {s}\n", .{@tagName(self.current_condition)});
        try writer.print("  {s}\n", .{self.current_condition.getDescription()});
        try writer.print("  Production: {d:.1}%\n", .{self.current_condition.getProductionMultiplier() * 100});
        try writer.print("  Operational costs: {d:.1}%\n", .{self.current_condition.getOperationalCostMultiplier() * 100});
        try writer.print("  Incident risk: {d:.1}%\n\n", .{self.current_condition.getIncidentRiskMultiplier() * 100});
        
        try writer.print("7-Day Forecast:\n", .{});
        for (self.forecast, 0..) |condition, i| {
            try writer.print("  Day {d}: {s}\n", .{i + 1, @tagName(condition)});
        }
        
        return try report.toOwnedSlice();
    }
};

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
    weather_system: WeatherSystem, // Added weather system
    region_type: RegionType, // Added region type
    player_bonuses: ?player_data.PlayerBonuses, // Character skills and other bonuses
    allocator: std.mem.Allocator,
    
    /// Initialize a new sandbox mode
    pub fn init(allocator: std.mem.Allocator) !SandboxMode {
        var simulation = try base_simulation.SimulationEngine.init(allocator);
        
        // Default to temperate region
        const region = RegionType.temperate;
        
        // Get player bonuses if available
        var bonuses: ?player_data.PlayerBonuses = null;
        if (player_data.getGlobalPlayerData()) |data| {
            bonuses = data.generateBonuses();
        }
        
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
            .weather_system = WeatherSystem.init(region, 1),
            .region_type = region,
            .player_bonuses = bonuses,
            .allocator = allocator,
        };
    }
    
    /// Set the region type
    pub fn setRegion(self: *SandboxMode, region: RegionType) void {
        // Check if region is unlocked via player progression
        if (player_data.getGlobalPlayerData()) |data| {
            const region_name = @tagName(region);
            if (!data.isRegionUnlocked(region_name)) {
                // Region not unlocked yet
                return;
            }
        }
        
        self.region_type = region;
        self.weather_system = WeatherSystem.init(region, self.current_day);
    }
    
    /// Get the current weather report
    pub fn getWeatherReport(self: *SandboxMode) ![]const u8 {
        return try self.weather_system.generateReport(self.allocator);
    }
    
    /// Clean up resources
    pub fn deinit(self: *SandboxMode) void {
        for (self.oil_fields.items) |field| {
            if (field.custom_notes) |notes| {
                self.allocator.free(notes);
            }
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
        
        // Apply the initial market conditions
        self.simulation.oil_price = scenario.getBasePrice();
    }
    
    /// Add a new oil field to the simulation
    pub fn addOilField(self: *SandboxMode, name: []const u8, size: f32, rate: f32, quality: f32, depth_multiplier: f32) !void {
        // Apply engineering skill bonus to extraction rate if available
        var modified_rate = rate;
        var modified_size = size;
        
        if (self.player_bonuses) |bonuses| {
            modified_rate = bonuses.applyToExtractionRate(rate);
            
            // Exploration skill increases field size discovery
            if (bonuses.discovery_chance_bonus > 0) {
                const size_bonus = 1.0 + (bonuses.discovery_chance_bonus * 0.5);
                modified_size = size * size_bonus;
            }
        }
        
        var field = try base_oil_field.OilField.init(
            self.allocator,
            modified_size,
            modified_rate,
            quality
        );
        
        var sandbox_field = SandboxOilField{
            .base = field,
            .custom_name = try self.allocator.dupe(u8, name),
            .discovery_date = self.current_day,
            .depth_multiplier = depth_multiplier,
            .custom_notes = null,
        };
        
        try self.oil_fields.append(sandbox_field);
        try self.simulation.addOilField(field);
        
        // Record largest field size for achievements/progression
        if (player_data.getGlobalPlayerData()) |data| {
            if (modified_size > data.largest_oilfield_size) {
                data.largest_oilfield_size = modified_size;
                
                // Try to save data
                _ = player_data.saveGlobalPlayerData() catch {};
            }
        }
    }
    
    /// Set notes for an oil field
    pub fn setOilFieldNotes(self: *SandboxMode, index: usize, notes: []const u8) !void {
        if (index >= self.oil_fields.items.len) {
            return error.InvalidIndex;
        }
        
        // Free existing notes if any
        if (self.oil_fields.items[index].custom_notes) |existing| {
            self.allocator.free(existing);
        }
        
        // Set new notes
        self.oil_fields.items[index].custom_notes = try self.allocator.dupe(u8, notes);
    }
    
    /// Set environmental factors
    pub fn setEnvironmentalFactors(self: *SandboxMode, disaster_chance: f32, regulatory_pressure: f32, public_opinion: f32) void {
        self.environmental_factors = EnvironmentalFactors{
            .disaster_chance = disaster_chance,
            .regulatory_pressure = regulatory_pressure,
            .public_opinion = public_opinion,
        };
    }
    
    /// Update the oil price based on market scenario
    pub fn updateOilPrice(self: *SandboxMode) !void {
        const base_price = self.market_scenario.getBasePrice();
        const volatility = self.market_scenario.getVolatility();
        
        // Generate a random price fluctuation
        var prng = std.rand.DefaultPrng.init(@intCast(self.current_day));
        var rand = prng.random();
        
        // Normal distribution approximation
        const u1 = rand.float(f32);
        const u2 = rand.float(f32);
        const z = @sqrt(-2.0 * @log(u1)) * @cos(2.0 * std.math.pi * u2);
        const price_change = z * volatility * base_price;
        
        // Apply scenario-specific trends
        var trend: f32 = 0.0;
        
        switch (self.market_scenario) {
            .boom => trend = 0.002 * base_price, // Upward trend in a boom
            .bust => trend = -0.002 * base_price, // Downward trend in a bust
            .shortage => if (self.current_day % 50 == 0) {
                trend = 0.05 * base_price; // Occasional price spikes in shortage
            },
            .oversupply => if (self.current_day % 30 == 0) {
                trend = -0.05 * base_price; // Occasional price drops in oversupply
            },
            else => {}, // No trend for other scenarios
        }
        
        // Calculate new price with limits to prevent negative or extreme values
        var new_price = self.simulation.oil_price + price_change + trend;
        new_price = std.math.max(new_price, base_price * 0.5);
        new_price = std.math.min(new_price, base_price * 2.0);
        
        // Apply player negotiation skill bonus if available
        if (self.player_bonuses) |bonuses| {
            new_price = bonuses.applyToOilPrice(new_price);
        }
        
        // Update price history every 10 days
        if (self.current_day % 10 == 0) {
            try self.price_history.append(PricePoint{
                .day = self.current_day,
                .price = new_price,
            });
        }
        
        // Set the new price in the simulation
        self.simulation.oil_price = new_price;
    }
    
    /// Check for environmental disasters
    pub fn checkEnvironmentalDisasters(self: *SandboxMode) !void {
        var disaster_chance = self.environmental_factors.disaster_chance;
        
        // Apply player environmental skill to reduce disaster risk
        if (self.player_bonuses) |bonuses| {
            disaster_chance = bonuses.applyToDisasterRisk(disaster_chance);
        }
        
        // Higher regulatory pressure reduces disaster chance
        disaster_chance *= (1.0 - (self.environmental_factors.regulatory_pressure * 0.5));
        
        // Basic random check for disaster
        var prng = std.rand.DefaultPrng.init(@intCast(self.current_day));
        var rand = prng.random();
        
        if (rand.float(f32) < disaster_chance) {
            // A disaster has occurred
            const field_index = rand.uintLessThan(usize, self.oil_fields.items.len);
            
            // Calculate cleanup cost based on field size and environmental factors
            const field = self.oil_fields.items[field_index];
            const field_size = field.base.max_capacity;
            const base_cleanup_cost = field_size * 0.5 * field.depth_multiplier;
            
            // Higher public opinion means higher cleanup costs (more pressure to do it right)
            const cleanup_multiplier = 1.0 + (self.environmental_factors.public_opinion * 0.5);
            const cleanup_cost = base_cleanup_cost * cleanup_multiplier;
            
            // Apply management skill to reduce cleanup costs if available
            var final_cleanup_cost = cleanup_cost;
            if (self.player_bonuses) |bonuses| {
                final_cleanup_cost = bonuses.applyToOperationalCosts(cleanup_cost);
            }
            
            // Calculate reputation damage
            const reputation_damage = (1.0 - self.environmental_factors.public_opinion) * 0.2;
            
            // Record the disaster
            try self.disaster_history.append(DisasterEvent{
                .day = self.current_day,
                .field_index = field_index,
                .field_name = field.custom_name,
                .cleanup_cost = final_cleanup_cost,
                .reputation_damage = reputation_damage,
            });
            
            // Apply the financial impact
            self.simulation.money -= final_cleanup_cost;
            
            // Update company reputation in player data
            if (player_data.getGlobalPlayerData()) |data| {
                data.company_reputation = std.math.max(0.0, data.company_reputation - (reputation_damage * 100.0));
                
                // Try to save data
                _ = player_data.saveGlobalPlayerData() catch {};
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
            // Update weather before simulating the day
            self.weather_system.updateForDay(self.current_day);
            
            // Apply weather effects to simulation
            const production_multiplier = self.weather_system.getCurrentProductionMultiplier();
            const cost_multiplier = self.weather_system.getCurrentCostMultiplier();
            const risk_multiplier = self.weather_system.getCurrentIncidentRiskMultiplier();
            
            // Temporarily modify extraction rates based on weather
            for (self.simulation.oil_fields.items) |*field| {
                field.extraction_rate *= production_multiplier;
            }
            
            // Run simulation step
            try self.simulation.step(1.0);
            
            // Apply additional costs based on weather
            var operational_costs = self.simulation.oil_fields.items.len * 10.0 * cost_multiplier;
            
            // Apply management efficiency bonus to operational costs if available
            if (self.player_bonuses) |bonuses| {
                operational_costs = bonuses.applyToOperationalCosts(operational_costs);
            }
            
            self.simulation.money -= operational_costs;
            
            // Restore original extraction rates
            for (self.simulation.oil_fields.items, 0..) |*field, idx| {
                if (idx < self.oil_fields.items.len) {
                    // Reset to the original extraction rate from our SandboxOilField
                    field.extraction_rate = self.oil_fields.items[idx].base.extraction_rate;
                }
            }
            
            self.current_day += 1;
            
            // Update price based on market conditions
            try self.updateOilPrice();
            
            // Apply weather effect to disaster chance
            const original_disaster_chance = self.environmental_factors.disaster_chance;
            self.environmental_factors.disaster_chance *= risk_multiplier;
            
            // Check for environmental disasters
            try self.checkEnvironmentalDisasters();
            
            // Restore original disaster chance
            self.environmental_factors.disaster_chance = original_disaster_chance;
        }
        
        // Update player data with earnings
        if (player_data.getGlobalPlayerData()) |data| {
            if (self.simulation.money > 0) {
                data.total_earnings += @as(f64, @floatCast(self.simulation.money * 0.01));
                data.company_value = @as(f64, @floatCast(self.simulation.money)) * 1.5;
                
                // Try to save data
                _ = player_data.saveGlobalPlayerData() catch {};
            }
        }
    }
    
    /// Generate a report of the current state
    pub fn generateReport(self: *SandboxMode, allocator: std.mem.Allocator) ![]const u8 {
        var report = std.ArrayList(u8).init(allocator);
        defer report.deinit();
        
        var writer = report.writer();
        
        try writer.print("=== Sandbox Simulation Report (Day {d}) ===\n\n", .{self.current_day});
        
        // Weather information
        try writer.print("Weather Conditions:\n", .{});
        try writer.print("  Region: {s}\n", .{@tagName(self.region_type)});
        try writer.print("  Current: {s}\n", .{@tagName(self.weather_system.current_condition)});
        try writer.print("  Effect on Production: {d:.1}%\n", .{self.weather_system.getCurrentProductionMultiplier() * 100});
        try writer.print("  Effect on Costs: {d:.1}%\n", .{self.weather_system.getCurrentCostMultiplier() * 100});
        try writer.print("  Effect on Incident Risk: {d:.1}%\n\n", .{self.weather_system.getCurrentIncidentRiskMultiplier() * 100});
        
        // Player bonuses section if available
        if (self.player_bonuses) |bonuses| {
            try writer.print("Player Bonuses:\n", .{});
            try writer.print("  Extraction Rate: +{d:.1}%\n", .{bonuses.extraction_rate_bonus * 100});
            try writer.print("  Discovery Chance: +{d:.1}%\n", .{bonuses.discovery_chance_bonus * 100});
            try writer.print("  Oil Price Negotiation: {d:.1}%\n", .{bonuses.negotiation_price_bonus * 100});
            try writer.print("  Disaster Risk Reduction: {d:.1}%\n", .{bonuses.disaster_risk_reduction * 100});
            try writer.print("  Operational Efficiency: {d:.1}%\n", .{bonuses.management_efficiency_bonus * 100});
            try writer.print("  Reputation Effect: {d:.1}%\n\n", .{bonuses.reputation_bonus * 100});
        }
        
        // Existing financial summary code...
        try writer.print("Financial Summary:\n", .{});
        try writer.print("  Total Money: ${d:.2}\n", .{self.simulation.money});
        try writer.print("  Current Oil Price: ${d:.2} per barrel\n", .{self.simulation.oil_price});
        try writer.print("  Total Oil Extracted: {d:.2} barrels\n\n", .{self.simulation.total_extracted});
        
        // Rest of the report remains the same...
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