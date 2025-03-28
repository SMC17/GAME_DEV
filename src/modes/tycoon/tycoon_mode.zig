const std = @import("std");
const simulation = @import("simulation");
const player_data = @import("player_data");
const terminal_ui = @import("terminal_ui");
const oil_field = @import("oil_field");

/// Main entry point for the tycoon mode
pub fn run() !void {
    // Get stdout for terminal output
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    
    const allocator = gpa.allocator();
    
    // Initialize the terminal UI
    var ui = terminal_ui.TerminalUI.init(std.io.getStdOut().writer(), allocator);
    
    try ui.clear();
    try ui.drawTitle("Tycoon Mode", .blue);
    try ui.println("Welcome to Tycoon Mode - Manage all aspects of your oil company!", .white, .normal);
    try ui.println("\nThis mode is currently under development.", .yellow, .italic);
    try ui.println("\nPress any key to return to the main menu...", .white, .normal);
    
    // Wait for user input
    _ = try std.io.getStdIn().reader().readByte();
}

/// Market condition that affects oil prices and business operations
pub const MarketCondition = enum {
    boom,
    stable,
    recession,
    crisis,
    
    /// Get the price multiplier for this market condition
    pub fn getPriceMultiplier(self: MarketCondition) f32 {
        return switch (self) {
            .boom => 1.5,
            .stable => 1.0,
            .recession => 0.7,
            .crisis => 0.4,
        };
    }
    
    /// Get the demand factor for this market condition
    pub fn getDemandFactor(self: MarketCondition) f32 {
        return switch (self) {
            .boom => 1.3,
            .stable => 1.0,
            .recession => 0.8,
            .crisis => 0.5,
        };
    }
    
    /// Get the investment return multiplier for this market condition
    pub fn getInvestmentMultiplier(self: MarketCondition) f32 {
        return switch (self) {
            .boom => 1.4,
            .stable => 1.0,
            .recession => 0.6,
            .crisis => 0.3,
        };
    }
};

/// Company department that can be upgraded
pub const Department = enum {
    research,
    production,
    marketing,
    hr,
    logistics,
    
    /// Get the cost to upgrade this department
    pub fn getUpgradeCost(self: Department, current_level: u32) f32 {
        const base_cost: f32 = switch (self) {
            .research => 50000.0,
            .production => 75000.0,
            .marketing => 40000.0,
            .hr => 30000.0,
            .logistics => 45000.0,
        };
        
        // Each level becomes more expensive
        return base_cost * std.math.pow(f32, 1.5, @as(f32, @floatFromInt(current_level)));
    }
    
    /// Get the benefits description for this department
    pub fn getBenefits(self: Department) []const u8 {
        return switch (self) {
            .research => "Improves technology, increasing extraction efficiency",
            .production => "Enhances oil field operations, increasing extraction rate",
            .marketing => "Raises oil sale prices through better market positioning",
            .hr => "Improves staff efficiency and reduces operating costs",
            .logistics => "Enhances supply chain, reducing costs and improving delivery",
        };
    }
};

/// Research project that can be funded
pub const ResearchProject = struct {
    name: []const u8,
    description: []const u8,
    cost: f32,
    duration_days: u32,
    days_researched: u32,
    completed: bool,
    
    /// Get the percentage complete for this project
    pub fn getPercentComplete(self: *const ResearchProject) f32 {
        if (self.completed) return 1.0;
        return @min(1.0, @as(f32, @floatFromInt(self.days_researched)) / @as(f32, @floatFromInt(self.duration_days)));
    }
    
    /// Advance research by one day
    pub fn advanceResearch(self: *ResearchProject) void {
        if (self.completed) return;
        
        self.days_researched += 1;
        if (self.days_researched >= self.duration_days) {
            self.completed = true;
        }
    }
};

/// Structure representing the tycoon mode
pub const TycoonMode = struct {
    oil_fields: std.ArrayList(oil_field.OilField),
    available_fields: std.ArrayList(oil_field.OilField),
    money: f32,
    company_value: f32,
    market_condition: MarketCondition,
    oil_price: f32,
    base_oil_price: f32,
    operating_costs: f32,
    research_projects: std.ArrayList(ResearchProject),
    active_research: ?*ResearchProject,
    department_levels: [5]u32, // One level for each department
    company_reputation: f32, // 0.0 to 1.0
    game_days: u32,
    market: MarketSimulation, // Market simulation
    player_market_share: f32, // Player's share of the global market
    player_production_rate: f32, // Player's total production in barrels per day
    allocator: std.mem.Allocator,
    
    /// Initialize a new tycoon mode
    pub fn init(allocator: std.mem.Allocator) !TycoonMode {
        const oil_fields = std.ArrayList(oil_field.OilField).init(allocator);
        const available_fields = std.ArrayList(oil_field.OilField).init(allocator);
        const research_projects = std.ArrayList(ResearchProject).init(allocator);
        
        // Initialize market simulation
        const market = try MarketSimulation.init(allocator);
        
        // Add initial research projects
        try research_projects.append(ResearchProject{
            .name = "Advanced Drilling",
            .description = "Improves drilling efficiency by 15%",
            .cost = 75000.0,
            .duration_days = 30,
            .days_researched = 0,
            .completed = false,
        });
        
        try research_projects.append(ResearchProject{
            .name = "Environmental Protection",
            .description = "Reduces environmental impact and improves reputation",
            .cost = 50000.0,
            .duration_days = 20,
            .days_researched = 0,
            .completed = false,
        });
        
        try research_projects.append(ResearchProject{
            .name = "Oil Quality Analysis",
            .description = "Enables better identification of high-quality oil fields",
            .cost = 60000.0,
            .duration_days = 25,
            .days_researched = 0,
            .completed = false,
        });
        
        // Create some available oil fields to purchase
        var field1 = oil_field.OilField.init(5000.0, 10.0);
        field1.quality = 0.8;
        field1.depth = 1.2;
        try available_fields.append(field1);
        
        var field2 = oil_field.OilField.init(12000.0, 8.0);
        field2.quality = 1.1;
        field2.depth = 1.5;
        try available_fields.append(field2);
        
        var field3 = oil_field.OilField.init(8000.0, 12.0);
        field3.quality = 0.9;
        field3.depth = 1.0;
        try available_fields.append(field3);
        
        return TycoonMode{
            .oil_fields = oil_fields,
            .available_fields = available_fields,
            .money = 500000.0, // Starting capital
            .company_value = 500000.0,
            .market_condition = .stable,
            .oil_price = market.current_oil_price,
            .base_oil_price = market.base_oil_price,
            .operating_costs = 5000.0, // Daily costs
            .research_projects = research_projects,
            .active_research = null,
            .department_levels = [_]u32{1} ** 5, // All departments start at level 1
            .company_reputation = 0.5, // Neutral reputation
            .game_days = 0,
            .market = market,
            .player_market_share = 0.01, // Starting with 1% market share
            .player_production_rate = 0.0, // No production yet
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *TycoonMode) void {
        self.oil_fields.deinit();
        self.available_fields.deinit();
        self.research_projects.deinit();
        self.market.deinit();
    }
    
    /// Purchase an oil field
    pub fn purchaseOilField(self: *TycoonMode, field_index: usize) !bool {
        if (field_index >= self.available_fields.items.len) {
            return false;
        }
        
        const field = self.available_fields.items[field_index];
        
        // Calculate field price based on size, quality, and market conditions
        const base_price = field.max_capacity * 10.0 * field.quality;
        const final_price = base_price * (1.0 - (0.5 * (1.0 - field.getPercentageFull())));
        
        if (self.money < final_price) {
            return false; // Not enough money
        }
        
        // Purchase the field
        self.money -= final_price;
        try self.oil_fields.append(field);
        
        // Remove from available fields
        _ = self.available_fields.orderedRemove(field_index);
        
        return true;
    }
    
    /// Upgrade a department
    pub fn upgradeDepartment(self: *TycoonMode, department: Department) bool {
        const dept_index = @intFromEnum(department);
        const current_level = self.department_levels[dept_index];
        const cost = department.getUpgradeCost(current_level);
        
        if (self.money < cost) {
            return false; // Not enough money
        }
        
        // Perform upgrade
        self.money -= cost;
        self.department_levels[dept_index] += 1;
        
        // Apply department benefits
        switch (department) {
            .research => {
                // Research benefits will be applied when using the active research project
            },
            .production => {
                // Improve all oil fields' extraction rates
                for (self.oil_fields.items) |*field| {
                    field.upgradeExtractionRate(1.0);
                }
            },
            .marketing => {
                // Improve oil selling price
                self.base_oil_price *= 1.05;
            },
            .hr => {
                // Reduce operating costs
                self.operating_costs *= 0.95;
            },
            .logistics => {
                // Combination of benefits
                self.operating_costs *= 0.97;
                self.base_oil_price *= 1.02;
            },
        }
        
        return true;
    }
    
    /// Start a research project
    pub fn startResearch(self: *TycoonMode, project_index: usize) bool {
        if (project_index >= self.research_projects.items.len) {
            return false;
        }
        
        const project = &self.research_projects.items[project_index];
        
        if (project.completed or project.days_researched > 0) {
            return false; // Already completed or in progress
        }
        
        if (self.money < project.cost) {
            return false; // Not enough money
        }
        
        // Start the project
        self.money -= project.cost;
        self.active_research = project;
        
        return true;
    }
    
    /// Calculate daily profit
    pub fn calculateDailyProfit(self: *TycoonMode) f32 {
        var total_extracted: f32 = 0.0;
        
        // Calculate extraction from all fields
        for (self.oil_fields.items) |*field| {
            // Apply production department bonus
            const prod_level = self.department_levels[@intFromEnum(Department.production)];
            const extraction_bonus = 1.0 + (0.05 * @as(f32, @floatFromInt(prod_level - 1)));
            
            total_extracted += field.extract(1.0) * extraction_bonus;
        }
        
        // Calculate revenue
        const market_level = self.department_levels[@intFromEnum(Department.marketing)];
        
        const price_multiplier = self.market_condition.getPriceMultiplier() * 
                               (1.0 + (0.03 * @as(f32, @floatFromInt(market_level - 1))));
        
        const revenue = total_extracted * self.oil_price * price_multiplier;
        
        // Apply operating costs
        const hr_level = self.department_levels[@intFromEnum(Department.hr)];
        const cost_reduction = 1.0 - (0.02 * @as(f32, @floatFromInt(hr_level - 1)));
        
        const daily_costs = self.operating_costs * cost_reduction;
        
        return revenue - daily_costs;
    }
    
    /// Update market conditions
    fn updateMarketConditions(self: *TycoonMode) void {
        if (self.game_days % 30 == 0) { // Change approximately monthly
            // Simple market condition change simulation
            const rand_val = @mod(self.game_days, 4);
            self.market_condition = @enumFromInt(rand_val);
            
            // Update oil price based on market conditions
            self.oil_price = self.base_oil_price * self.market_condition.getPriceMultiplier();
        }
    }
    
    /// Simulate a stock market value for the company
    fn calculateCompanyValue(self: *TycoonMode) f32 {
        var field_value: f32 = 0.0;
        
        // Value from oil fields
        for (self.oil_fields.items) |field| {
            field_value += field.oil_amount * self.oil_price * field.quality;
        }
        
        // Base value from money
        const base_value = self.money;
        
        // Value from infrastructure (departments)
        var infrastructure_value: f32 = 0.0;
        for (self.department_levels) |level| {
            infrastructure_value += 50000.0 * @as(f32, @floatFromInt(level));
        }
        
        // Value from research and reputation
        const research_value = 100000.0 * self.company_reputation;
        
        // Combined value
        return base_value + field_value + infrastructure_value + research_value;
    }
    
    /// Generate a new random oil field to purchase
    pub fn generateNewOilField(self: *TycoonMode) !void {
        const research_level = self.department_levels[@intFromEnum(Department.research)];
        const quality_bonus = 0.05 * @as(f32, @floatFromInt(research_level - 1));
        
        // Base field characteristics
        const size_options = [_]f32{ 3000.0, 5000.0, 8000.0, 12000.0, 20000.0 };
        const rate_options = [_]f32{ 5.0, 8.0, 10.0, 15.0, 20.0 };
        const quality_options = [_]f32{ 0.7, 0.8, 0.9, 1.0, 1.1, 1.2 };
        const depth_options = [_]f32{ 0.8, 1.0, 1.2, 1.5, 2.0 };
        
        // Use game days as simple random seed (in real game use actual RNG)
        const size_index = @mod(self.game_days, size_options.len);
        const rate_index = @mod(self.game_days + 1, rate_options.len);
        const quality_index = @mod(self.game_days + 2, quality_options.len);
        const depth_index = @mod(self.game_days + 3, depth_options.len);
        
        var new_field = oil_field.OilField.init(size_options[size_index], rate_options[rate_index]);
        new_field.quality = quality_options[quality_index] + quality_bonus;
        new_field.depth = depth_options[depth_index];
        
        try self.available_fields.append(new_field);
    }
    
    /// Process a day in the tycoon mode
    pub fn advanceDay(self: *TycoonMode) !void {
        self.game_days += 1;
        
        // Update market simulation first
        try self.market.simulateDay();
        
        // Update market condition and oil price from market simulation
        self.market_condition = self.market.current_condition;
        self.oil_price = self.market.current_oil_price;
        
        // Calculate daily production from all fields
        var total_extracted: f32 = 0;
        var total_capacity: f32 = 0;
        
        for (self.oil_fields.items) |*field| {
            // Calculate extraction modified by department levels
            const production_modifier = 1.0 + @as(f32, @floatFromInt(self.department_levels[@intFromEnum(Department.production)])) * 0.1;
            const extraction_rate = field.extraction_rate * field.quality * production_modifier;
            
            // Apply market condition modifier to extraction rate
            const market_modifier = self.market_condition.getDemandFactor();
            const final_extraction = extraction_rate * market_modifier;
            
            // Extract oil
            const extracted = field.extract(1.0) * final_extraction;
            total_extracted += extracted;
            total_capacity += field.max_capacity;
        }
        
        // Update player's production rate and market share
        self.player_production_rate = total_extracted;
        
        // Calculate global production (player + competitors)
        var global_production: f32 = self.player_production_rate;
        for (self.market.competitors.items) |competitor| {
            global_production += competitor.production_rate;
        }
        
        // Update market share if global production is non-zero
        if (global_production > 0) {
            self.player_market_share = self.player_production_rate / global_production;
        }
        
        // Apply price multipliers based on marketing department level
        const marketing_multiplier = 1.0 + @as(f32, @floatFromInt(self.department_levels[@intFromEnum(Department.marketing)])) * 0.05;
        const effective_price = self.oil_price * marketing_multiplier;
        
        // Calculate daily income
        const daily_income = total_extracted * effective_price;
        
        // Apply operating costs modified by HR department level
        const hr_efficiency = 1.0 - @as(f32, @floatFromInt(self.department_levels[@intFromEnum(Department.hr)])) * 0.05;
        const daily_costs = self.operating_costs * @max(0.5, hr_efficiency) * (1.0 + @as(f32, @floatFromInt(self.oil_fields.items.len)) * 0.1);
        
        // Update company finances
        self.money += daily_income - daily_costs;
        
        // Update company value based on assets and cash
        const asset_value = total_capacity * self.oil_price * 0.5; // Half of total oil as asset value
        self.company_value = self.money + asset_value + (self.player_market_share * 10_000_000.0); // Market share has value
        
        // Advance research if active
        if (self.active_research) |project| {
            // Research speed is affected by research department level
            const research_speed = 1.0 + @as(f32, @floatFromInt(self.department_levels[@intFromEnum(Department.research)])) * 0.2;
            const days_progress = @max(1, @as(u32, @intFromFloat(research_speed)));
            
            var i: u32 = 0;
            while (i < days_progress) : (i += 1) {
                project.advanceResearch();
            }
            
            // Check if research is completed
            if (project.completed) {
                self.active_research = null;
                
                // Apply research benefits
                if (std.mem.eql(u8, project.name, "Advanced Drilling")) {
                    // Improve all fields extraction rate
                    for (self.oil_fields.items) |*field| {
                        field.extraction_rate *= 1.15;
                    }
                } else if (std.mem.eql(u8, project.name, "Environmental Protection")) {
                    // Improve reputation
                    self.company_reputation = @min(1.0, self.company_reputation + 0.15);
                } else if (std.mem.eql(u8, project.name, "Oil Quality Analysis")) {
                    // Improve field quality detection - generate new higher quality fields
                    try self.generateNewFields(3, 1.2);
                }
            }
        }
        
        // Chance for reputation effects from world events
        for (self.market.active_events.items) |event| {
            self.company_reputation += event.reputation_impact / @as(f32, @floatFromInt(event.duration_days));
        }
        
        // Keep reputation in valid range
        self.company_reputation = @max(0.0, @min(1.0, self.company_reputation));
        
        // Chance to generate new available fields to purchase
        if (std.crypto.random.float(f32) < 0.1) {
            try self.generateNewFields(1, 1.0);
        }
        
        // Occasionally update operating costs based on inflation and company size
        if (self.game_days % 30 == 0) {
            self.operating_costs *= 1.01 + @as(f32, @floatFromInt(self.oil_fields.items.len)) * 0.01;
        }
    }
    
    /// Generate new oil fields for purchase
    pub fn generateNewFields(self: *TycoonMode, count: usize, quality_multiplier: f32) !void {
        var i: usize = 0;
        while (i < count) : (i += 1) {
            // Random size
            const size_factor = std.crypto.random.float(f32) * 2.0 + 0.5; // 0.5 to 2.5
            const size = 5000.0 + size_factor * 5000.0;
            
            // Random extraction rate
            const rate_factor = std.crypto.random.float(f32) + 0.5; // 0.5 to 1.5
            const rate = 5.0 + rate_factor * 10.0;
            
            var new_field = oil_field.OilField.init(size, rate);
            
            // Quality affected by research and random factors
            const quality_factor = std.crypto.random.float(f32) * 0.5 + 0.7; // 0.7 to 1.2
            new_field.quality = quality_factor * quality_multiplier;
            
            // Depth affects difficulty
            const depth_factor = std.crypto.random.float(f32) * 1.5 + 0.5; // 0.5 to 2.0
            new_field.depth = depth_factor;
            
            try self.available_fields.append(new_field);
        }
    }
};

/// World event that can affect the market and gameplay
pub const WorldEvent = struct {
    name: []const u8,
    description: []const u8,
    price_impact: f32, // Multiplier for oil price (e.g., 1.2 = 20% increase)
    demand_impact: f32, // Multiplier for oil demand
    reputation_impact: f32, // Direct change to company reputation (-1.0 to 1.0)
    duration_days: u32, // How long the event lasts
    days_active: u32, // How many days it has been active
    is_active: bool,
    
    /// Determine if the event is still in effect
    pub fn isActive(self: *const WorldEvent) bool {
        return self.is_active and self.days_active < self.duration_days;
    }
    
    /// Advance the event by one day
    pub fn advanceDay(self: *WorldEvent) void {
        if (self.is_active) {
            self.days_active += 1;
            if (self.days_active >= self.duration_days) {
                self.is_active = false;
            }
        }
    }
};

/// Competitor company in the oil market
pub const Competitor = struct {
    name: []const u8,
    size: f32, // Market share (0.0 to 1.0)
    aggressiveness: f32, // How aggressive their strategy is (0.0 to 1.0)
    production_rate: f32, // Barrels per day
    fields_owned: u32,
    technological_level: f32, // 0.0 to 1.0
    reputation: f32, // 0.0 to 1.0
    
    // Personality traits that influence decision making
    risk_tolerance: f32, // 0.0 to 1.0, influences willingness to take chances
    innovation_focus: f32, // 0.0 to 1.0, influences tech investment vs traditional production
    environmental_concern: f32, // 0.0 to 1.0, influences reputation management
    expansion_priority: f32, // 0.0 to 1.0, influences field acquisition vs efficiency
    
    // Strategy state
    strategy: CompetitorStrategy, // Current active strategy
    strategy_cooldown: u32, // Days before strategy can change
    funds: f32, // Available funds for operations
    price_modifier: f32, // How much they modify market price in sales
    
    // Business intelligence
    known_oil_reserves: f32, // Estimated remaining oil in fields
    historical_production: [30]f32 = [_]f32{0.0} ** 30, // Last 30 days of production
    
    /// Initialize a competitor with a specific strategy profile
    pub fn init(name: []const u8, profile: CompetitorProfile) Competitor {
        return Competitor{
            .name = name,
            .size = profile.starting_size,
            .aggressiveness = profile.aggressiveness,
            .production_rate = profile.starting_production,
            .fields_owned = profile.starting_fields,
            .technological_level = profile.starting_tech,
            .reputation = profile.starting_reputation,
            .risk_tolerance = profile.risk_tolerance,
            .innovation_focus = profile.innovation_focus,
            .environmental_concern = profile.environmental_concern,
            .expansion_priority = profile.expansion_priority,
            .strategy = profile.default_strategy,
            .strategy_cooldown = 0,
            .funds = profile.starting_funds,
            .price_modifier = 1.0,
            .known_oil_reserves = profile.starting_production * 500.0, // Rough estimate
        };
    }
    
    /// Competitor strategy profiles for initialization
    pub const CompetitorProfile = struct {
        starting_size: f32,
        aggressiveness: f32,
        starting_production: f32,
        starting_fields: u32,
        starting_tech: f32,
        starting_reputation: f32,
        risk_tolerance: f32,
        innovation_focus: f32,
        environmental_concern: f32,
        expansion_priority: f32,
        default_strategy: CompetitorStrategy,
        starting_funds: f32,
    };
    
    /// Predefined competitor profiles
    pub const profiles = struct {
        pub const aggressive_expander = CompetitorProfile{
            .starting_size = 0.25,
            .aggressiveness = 0.85,
            .starting_production = 500000.0,
            .starting_fields = 12,
            .starting_tech = 0.65,
            .starting_reputation = 0.45,
            .risk_tolerance = 0.8,
            .innovation_focus = 0.5,
            .environmental_concern = 0.2,
            .expansion_priority = 0.9,
            .default_strategy = .market_domination,
            .starting_funds = 2500000.0,
        };
        
        pub const balanced_operator = CompetitorProfile{
            .starting_size = 0.35,
            .aggressiveness = 0.5,
            .starting_production = 750000.0,
            .starting_fields = 20,
            .starting_tech = 0.75,
            .starting_reputation = 0.7,
            .risk_tolerance = 0.5,
            .innovation_focus = 0.5,
            .environmental_concern = 0.5,
            .expansion_priority = 0.5,
            .default_strategy = .balanced_growth,
            .starting_funds = 5000000.0,
        };
        
        pub const eco_innovator = CompetitorProfile{
            .starting_size = 0.15,
            .aggressiveness = 0.3,
            .starting_production = 300000.0,
            .starting_fields = 8,
            .starting_tech = 0.9,
            .starting_reputation = 0.9,
            .risk_tolerance = 0.4,
            .innovation_focus = 0.9,
            .environmental_concern = 0.9,
            .expansion_priority = 0.3,
            .default_strategy = .technological_leadership,
            .starting_funds = 3000000.0,
        };
        
        pub const conservative_giant = CompetitorProfile{
            .starting_size = 0.45,
            .aggressiveness = 0.2,
            .starting_production = 1000000.0,
            .starting_fields = 30,
            .starting_tech = 0.6,
            .starting_reputation = 0.6,
            .risk_tolerance = 0.2,
            .innovation_focus = 0.4,
            .environmental_concern = 0.3,
            .expansion_priority = 0.2,
            .default_strategy = .conservative_optimization,
            .starting_funds = 8000000.0,
        };
        
        pub const speculative_upstart = CompetitorProfile{
            .starting_size = 0.05,
            .aggressiveness = 0.7,
            .starting_production = 100000.0,
            .starting_fields = 3,
            .starting_tech = 0.8,
            .starting_reputation = 0.4,
            .risk_tolerance = 0.9,
            .innovation_focus = 0.8,
            .environmental_concern = 0.4,
            .expansion_priority = 0.7,
            .default_strategy = .opportunistic_growth,
            .starting_funds = 1000000.0,
        };
    };
    
    /// Possible strategies a competitor can adopt
    pub const CompetitorStrategy = enum {
        market_domination, // Focus on rapid expansion regardless of cost
        technological_leadership, // Focus on technological advancement
        balanced_growth, // Maintain steady growth across all areas
        conservative_optimization, // Minimize risk, focus on efficiency
        opportunistic_growth, // Exploit market conditions flexibly
        reputation_building, // Focus on improving corporate image
        crisis_management, // Cut costs during downturns
        
        /// Get a description of the strategy
        pub fn getDescription(self: CompetitorStrategy) []const u8 {
            return switch (self) {
                .market_domination => "Rapidly expanding production and market share through aggressive field acquisition",
                .technological_leadership => "Investing heavily in technology to maximize extraction efficiency and minimize costs",
                .balanced_growth => "Pursuing a balanced approach to growth, maintaining stability across all operations",
                .conservative_optimization => "Focusing on optimizing existing operations while minimizing expansion risks",
                .opportunistic_growth => "Flexibly adapting to market conditions to exploit temporary opportunities",
                .reputation_building => "Building corporate reputation through environmental initiatives and PR campaigns",
                .crisis_management => "Cutting costs and securing operations during market downturns",
            };
        }
    };
    
    /// Simulate the competitor's daily actions
    pub fn simulateDay(self: *Competitor, market_condition: MarketCondition, global_price: f32) void {
        // Update strategy if needed
        if (self.strategy_cooldown == 0) {
            self.evaluateStrategy(market_condition);
        } else {
            self.strategy_cooldown -= 1;
        }
        
        // Track production history
        for (1..self.historical_production.len) |i| {
            self.historical_production[i-1] = self.historical_production[i];
        }
        self.historical_production[self.historical_production.len - 1] = self.production_rate;
        
        // Calculate daily revenue based on production and price
        const daily_revenue = self.production_rate * global_price * self.price_modifier;
        
        // Calculate operating costs based on fields and technology
        const base_operating_cost = self.production_rate * 0.2;
        const tech_efficiency = 1.0 - (self.technological_level * 0.3);
        const operating_costs = base_operating_cost * tech_efficiency * (1.0 + @as(f32, @floatFromInt(self.fields_owned)) * 0.02);
        
        // Daily profit
        const daily_profit = daily_revenue - operating_costs;
        self.funds += daily_profit;
        
        // Execute strategy-specific actions
        switch (self.strategy) {
            .market_domination => {
                // Aggressive expansion - invest heavily in new fields
                if (self.funds > self.production_rate * 0.5 and std.crypto.random.float(f32) < 0.1 * self.expansion_priority) {
                    self.acquireNewField();
                }
                
                // Maximize production from existing fields
                self.production_rate *= 1.001 + (self.aggressiveness * 0.002);
                
                // Price competitively to gain market share
                self.price_modifier = 0.95;
                
                // Risk reputation for growth
                if (std.crypto.random.float(f32) < 0.05) {
                    self.reputation = @max(0.1, self.reputation - 0.01);
                }
            },
            .technological_leadership => {
                // Invest in technology
                if (self.funds > self.production_rate * 0.3 and std.crypto.random.float(f32) < 0.2 * self.innovation_focus) {
                    const investment = self.funds * 0.1;
                    self.funds -= investment;
                    self.technological_level = @min(1.0, self.technological_level + (investment / 10000000.0));
                }
                
                // Modest production growth focused on efficiency
                self.production_rate *= 1.0005 + (self.technological_level * 0.001);
                
                // Price at premium due to efficiency
                self.price_modifier = 1.05;
                
                // Technology investments boost reputation
                if (std.crypto.random.float(f32) < 0.05) {
                    self.reputation = @min(1.0, self.reputation + 0.005);
                }
            },
            .balanced_growth => {
                // Moderate investments across all areas
                if (self.funds > self.production_rate * 0.4) {
                    // Split investments between fields, tech, and reputation
                    const total_investment = self.funds * 0.05;
                    self.funds -= total_investment;
                    
                    // 40% to field expansion
                    if (std.crypto.random.float(f32) < 0.05) {
                        self.acquireNewField();
                    }
                    
                    // 30% to technology
                    self.technological_level = @min(1.0, self.technological_level + (total_investment * 0.3 / 5000000.0));
                    
                    // 30% to reputation building
                    if (std.crypto.random.float(f32) < 0.1) {
                        self.reputation = @min(1.0, self.reputation + 0.01);
                    }
                }
                
                // Steady production growth
                self.production_rate *= 1.0007;
                
                // Standard pricing
                self.price_modifier = 1.0;
            },
            .conservative_optimization => {
                // Focus on optimizing existing operations
                if (self.funds > self.production_rate * 0.2) {
                    // Invest mainly in efficiency improvements
                    const investment = self.funds * 0.03;
                    self.funds -= investment;
                    self.technological_level = @min(1.0, self.technological_level + (investment / 7000000.0));
                }
                
                // Very slow, cautious growth
                self.production_rate *= 1.0003;
                
                // Slightly premium pricing to maintain margins
                self.price_modifier = 1.02;
                
                // Maintain solid reputation
                if (std.crypto.random.float(f32) < 0.03) {
                    self.reputation = @min(0.95, self.reputation + 0.002);
                }
            },
            .opportunistic_growth => {
                // Adapt based on market conditions
                if (market_condition == .boom) {
                    // In boom times, expand rapidly
                    if (self.funds > self.production_rate * 0.3 and std.crypto.random.float(f32) < 0.15) {
                        self.acquireNewField();
                    }
                    
                    // Significant production increase
                    self.production_rate *= 1.002;
                    
                    // Capitalize on high prices
                    self.price_modifier = 1.08;
                } else if (market_condition == .crisis) {
                    // In crisis, cut costs and consolidate
                    self.production_rate *= 0.998;
                    
                    // Competitive pricing to maintain sales
                    self.price_modifier = 0.92;
                    
                    // Build cash reserves
                    if (std.crypto.random.float(f32) < 0.2) {
                        // Small chance to opportunistically acquire struggling competitors
                        if (self.funds > self.production_rate * 1.0 and std.crypto.random.float(f32) < 0.05) {
                            self.acquireNewField();
                        }
                    }
                } else {
                    // Normal growth in stable conditions
                    self.production_rate *= 1.0005;
                    self.price_modifier = 1.0;
                }
            },
            .reputation_building => {
                // Invest heavily in reputation
                if (self.funds > self.production_rate * 0.3) {
                    const investment = self.funds * 0.08;
                    self.funds -= investment;
                    self.reputation = @min(1.0, self.reputation + (investment / 2000000.0));
                }
                
                // Focus on sustainable growth
                self.production_rate *= 1.0004;
                
                // Premium pricing based on reputation
                self.price_modifier = 1.0 + (self.reputation * 0.1);
                
                // Occasional technology improvements
                if (std.crypto.random.float(f32) < 0.05 and self.funds > self.production_rate * 0.2) {
                    const tech_investment = self.funds * 0.05;
                    self.funds -= tech_investment;
                    self.technological_level = @min(1.0, self.technological_level + (tech_investment / 8000000.0));
                }
            },
            .crisis_management => {
                // Drastically cut costs
                self.production_rate *= 0.997;
                
                // Discount pricing to maintain cash flow
                self.price_modifier = 0.9;
                
                // Focus on efficiency
                if (self.funds > self.production_rate * 0.1 and std.crypto.random.float(f32) < 0.1) {
                    const efficiency_investment = self.funds * 0.05;
                    self.funds -= efficiency_investment;
                    self.technological_level = @min(1.0, self.technological_level + (efficiency_investment / 6000000.0));
                }
                
                // Improve reputation to survive the crisis
                if (std.crypto.random.float(f32) < 0.08) {
                    self.reputation = @min(1.0, self.reputation + 0.005);
                }
            },
        }
        
        // Apply market condition modifiers to production
        const market_factor = market_condition.getDemandFactor();
        
        // Strategic response to market conditions varies by risk tolerance
        if (market_factor < 1.0) {
            if (self.risk_tolerance > 0.7) {
                // High risk tolerance companies maintain higher production in downturns
                self.production_rate *= @max(market_factor, 0.95);
            } else if (self.risk_tolerance < 0.3) {
                // Conservative companies cut production more in downturns
                self.production_rate *= @max(market_factor * 0.9, 0.9);
            } else {
                // Moderate adjustment
                self.production_rate *= @max(market_factor, 0.92);
            }
        } else if (market_factor > 1.0) {
            // In boom conditions
            if (self.risk_tolerance > 0.7) {
                // Aggressive companies ramp up quickly
                self.production_rate *= @min(market_factor * 1.1, 1.1);
            } else if (self.risk_tolerance < 0.3) {
                // Conservative companies expand cautiously
                self.production_rate *= @min(market_factor * 0.9, 1.05);
            } else {
                // Moderate expansion
                self.production_rate *= @min(market_factor, 1.07);
            }
        }
        
        // Depletion of oil reserves
        self.known_oil_reserves -= self.production_rate;
        if (self.known_oil_reserves < self.production_rate * 100.0) {
            // If reserves are running low, automatically look for new fields
            if (self.funds > self.production_rate * 0.5 and std.crypto.random.float(f32) < 0.2) {
                self.acquireNewField();
            }
        }
        
        // Prevent production from exceeding reserves
        if (self.known_oil_reserves < self.production_rate * 30.0) {
            self.production_rate = self.known_oil_reserves / 50.0;
        }
        
        // Update market share based on production (will be adjusted by market simulation)
        self.size = @min(1.0, self.size * 0.99 + self.production_rate / 10000000.0);
    }
    
    /// Evaluate and potentially change the company's strategy
    fn evaluateStrategy(self: *Competitor, market_condition: MarketCondition) void {
        // Analyze recent production trend (30-day average)
        var avg_production: f32 = 0;
        for (self.historical_production) |prod| {
            avg_production += prod;
        }
        avg_production /= @as(f32, @floatFromInt(self.historical_production.len));
        
        // Decision factors
        const funds_healthy = self.funds > self.production_rate * 0.5;
        const reserves_low = self.known_oil_reserves < self.production_rate * 200.0;
        
        // Base chance to change strategy
        var change_chance: f32 = 0.05;
        
        // Adjust based on market conditions and risk tolerance
        if (market_condition == .crisis) {
            change_chance += 0.2;
        } else if (market_condition == .recession) {
            change_chance += 0.1;
        } else if (market_condition == .boom) {
            change_chance += 0.05;
        }
        
        // Risk tolerance affects willingness to change strategy
        change_chance *= 0.5 + self.risk_tolerance;
        
        // Decide whether to change strategy
        if (std.crypto.random.float(f32) < change_chance) {
            // Choose a new strategy based on conditions
            if (market_condition == .crisis) {
                // During crisis, conservative approaches are more likely
                if (self.risk_tolerance < 0.4 or !funds_healthy) {
                    self.strategy = .crisis_management;
                } else if (self.risk_tolerance > 0.8 and funds_healthy) {
                    // Very risk-tolerant might see opportunity in crisis
                    self.strategy = .opportunistic_growth;
                } else {
                    self.strategy = .conservative_optimization;
                }
            } else if (market_condition == .recession) {
                // During recession, adapt based on financial health
                if (!funds_healthy) {
                    self.strategy = .conservative_optimization;
                } else if (self.reputation < 0.4) {
                    // Low reputation companies might focus on rebuilding
                    self.strategy = .reputation_building;
                } else if (self.innovation_focus > 0.7) {
                    // Innovation-focused companies invest in tech during downturns
                    self.strategy = .technological_leadership;
                } else {
                    self.strategy = .balanced_growth;
                }
            } else if (market_condition == .boom) {
                // During boom, expansion strategies are more attractive
                if (self.expansion_priority > 0.7 and funds_healthy) {
                    self.strategy = .market_domination;
                } else if (self.technological_level < 0.5 and funds_healthy) {
                    // Companies with low tech might catch up during good times
                    self.strategy = .technological_leadership;
                } else if (reserves_low) {
                    // If reserves are low, focus on new acquisitions
                    self.strategy = .opportunistic_growth;
                } else {
                    self.strategy = .balanced_growth;
                }
            } else {
                // During stable times, companies focus on their core priorities
                if (self.environmental_concern > 0.7) {
                    self.strategy = .reputation_building;
                } else if (self.innovation_focus > 0.7) {
                    self.strategy = .technological_leadership;
                } else if (self.expansion_priority > 0.7 and funds_healthy) {
                    self.strategy = .market_domination;
                } else if (reserves_low) {
                    self.strategy = .opportunistic_growth;
                } else {
                    self.strategy = .balanced_growth;
                }
            }
            
            // Set cooldown before next strategy change
            self.strategy_cooldown = @max(10, @as(u32, @intFromFloat(30.0 * (1.0 - self.risk_tolerance))));
        }
    }
    
    /// Simulate acquiring a new oil field
    fn acquireNewField(self: *Competitor) void {
        // Random field size based on expansion strategy and funds
        const field_size = std.crypto.random.float(f32) * 10000.0 + 5000.0;
        const field_cost = field_size * 10.0;
        
        // Check if company can afford it
        if (self.funds >= field_cost) {
            self.funds -= field_cost;
            self.fields_owned += 1;
            self.known_oil_reserves += field_size;
            
            // Production capacity increases with new field
            const prod_increase = field_size / 200.0; // Each field produces ~0.5% of its size per day
            self.production_rate += prod_increase;
        }
    }
    
    /// Get a description of competitor's current strategy and status
    pub fn getStatusDescription(self: *const Competitor) []const u8 {
        const strategy_desc = self.strategy.getDescription();
        return strategy_desc;
    }
};

/// Market simulation for the tycoon mode
pub const MarketSimulation = struct {
    current_condition: MarketCondition,
    base_oil_price: f32,
    current_oil_price: f32,
    global_demand: f32, // In millions of barrels per day
    global_supply: f32, // In millions of barrels per day
    volatility: f32, // How much prices fluctuate (0.0 to 1.0)
    competitors: std.ArrayList(Competitor),
    active_events: std.ArrayList(WorldEvent),
    possible_events: std.ArrayList(WorldEvent),
    price_history: std.ArrayList(f32),
    demand_history: std.ArrayList(f32),
    arena: std.heap.ArenaAllocator, // Arena allocator for efficient memory management
    parent_allocator: std.mem.Allocator, // Store the parent allocator for reset operations
    
    /// Initialize a new market simulation
    pub fn init(allocator: std.mem.Allocator) !MarketSimulation {
        // Create an arena allocator backed by the parent allocator
        var arena = std.heap.ArenaAllocator.init(allocator);
        // Get an allocator that allocates from the arena
        const arena_allocator = arena.allocator();
        
        // Initialize all array lists from the arena allocator
        const competitors = std.ArrayList(Competitor).init(arena_allocator);
        const active_events = std.ArrayList(WorldEvent).init(arena_allocator);
        const possible_events = std.ArrayList(WorldEvent).init(arena_allocator);
        const price_history = std.ArrayList(f32).init(arena_allocator);
        const demand_history = std.ArrayList(f32).init(arena_allocator);
        
        // Add initial competitors with diverse personalities and strategies
        try competitors.append(Competitor.init("PetroCorp", Competitor.profiles.aggressive_expander));
        try competitors.append(Competitor.init("Global Oil", Competitor.profiles.balanced_operator));
        try competitors.append(Competitor.init("EcoFuels", Competitor.profiles.eco_innovator));
        try competitors.append(Competitor.init("MegaPetrol", Competitor.profiles.conservative_giant));
        try competitors.append(Competitor.init("NexGen Drilling", Competitor.profiles.speculative_upstart));
        
        // Preallocate event data using comptime strings
        const events = [_]struct { name: []const u8, desc: []const u8, price: f32, demand: f32, rep: f32, days: u32 }{
            .{ 
                .name = "Middle East Conflict", 
                .desc = "Political tensions have erupted into conflict, threatening oil supplies.",
                .price = 1.5,
                .demand = 1.1,
                .rep = 0.0,
                .days = 14,
            },
            .{ 
                .name = "Major Oil Spill", 
                .desc = "A competitor's tanker has caused a major environmental disaster.",
                .price = 1.1,
                .demand = 0.95,
                .rep = -0.1,
                .days = 30,
            },
            .{ 
                .name = "New Oil Field Discovery", 
                .desc = "A massive new oil field has been discovered, increasing global supplies.",
                .price = 0.85,
                .demand = 1.0,
                .rep = 0.0,
                .days = 60,
            },
            .{ 
                .name = "Global Recession", 
                .desc = "Economic downturn has reduced demand for oil worldwide.",
                .price = 0.7,
                .demand = 0.8,
                .rep = 0.0,
                .days = 90,
            },
            .{ 
                .name = "Alternative Energy Breakthrough", 
                .desc = "A significant advancement in renewable energy is affecting oil markets.",
                .price = 0.9,
                .demand = 0.9,
                .rep = 0.0,
                .days = 120,
            },
            .{ 
                .name = "Transportation Strike", 
                .desc = "Workers across the transportation sector are on strike.",
                .price = 0.95,
                .demand = 0.85,
                .rep = 0.0,
                .days = 14,
            },
            .{ 
                .name = "International Energy Summit", 
                .desc = "Global leaders are meeting to discuss energy policies.",
                .price = 1.1,
                .demand = 1.0,
                .rep = 0.0,
                .days = 7,
            },
            .{ 
                .name = "Refinery Explosion", 
                .desc = "A major refinery has experienced a catastrophic explosion.",
                .price = 1.3,
                .demand = 1.0,
                .rep = -0.05,
                .days = 21,
            },
            .{ 
                .name = "Cold Weather Snap", 
                .desc = "Unusually cold weather has increased heating oil demand.",
                .price = 1.2,
                .demand = 1.15,
                .rep = 0.0,
                .days = 10,
            },
            .{ 
                .name = "New Emission Regulations", 
                .desc = "Stricter emissions standards are now in effect for oil companies.",
                .price = 1.05,
                .demand = 0.95,
                .rep = 0.0,
                .days = 180,
            },
        };
        
        // Add possible world events using the predefined array
        for (events) |event_data| {
            try possible_events.append(WorldEvent{
                .name = event_data.name,
                .description = event_data.desc,
                .price_impact = event_data.price,
                .demand_impact = event_data.demand,
                .reputation_impact = event_data.rep,
                .duration_days = event_data.days,
                .days_active = 0,
                .is_active = false,
            });
        }
        
        // Pre-allocate space for a year of history to avoid frequent reallocations
        try price_history.ensureTotalCapacity(365);
        try demand_history.ensureTotalCapacity(365);
        
        // Initialize with current price - slightly randomized
        const initial_price = 45.0 + std.crypto.random.float(f32) * 10.0;
        try price_history.append(initial_price);
        
        // Initialize with current demand - slightly randomized
        const initial_demand = 95.0 + std.crypto.random.float(f32) * 10.0; // ~100 million barrels per day
        try demand_history.append(initial_demand);
        
        return MarketSimulation{
            .current_condition = .stable,
            .base_oil_price = initial_price,
            .current_oil_price = initial_price,
            .global_demand = initial_demand,
            .global_supply = initial_demand * (0.98 + std.crypto.random.float(f32) * 0.04), // Slightly balanced supply/demand
            .volatility = 0.05 + std.crypto.random.float(f32) * 0.1, // Random initial volatility
            .competitors = competitors,
            .active_events = active_events,
            .possible_events = possible_events,
            .price_history = price_history,
            .demand_history = demand_history,
            .arena = arena,
            .parent_allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *MarketSimulation) void {
        // With arena allocator, we just need to deinit the arena itself
        // which frees all memory allocated from it at once
        self.arena.deinit();
    }
    
    /// Reset the simulation state while keeping the same allocators
    pub fn reset(self: *MarketSimulation) !void {
        // Deinitialize the arena without destroying it
        const allocator = self.parent_allocator;
        
        // Destroy the old arena
        self.arena.deinit();
        
        // Create a new arena with the same parent allocator
        self.arena = std.heap.ArenaAllocator.init(allocator);
        const arena_allocator = self.arena.allocator();
        
        // Reinitialize array lists
        self.competitors = std.ArrayList(Competitor).init(arena_allocator);
        self.active_events = std.ArrayList(WorldEvent).init(arena_allocator);
        self.possible_events = std.ArrayList(WorldEvent).init(arena_allocator);
        self.price_history = std.ArrayList(f32).init(arena_allocator);
        self.demand_history = std.ArrayList(f32).init(arena_allocator);
        
        // Preallocate history capacity
        try self.price_history.ensureTotalCapacity(365);
        try self.demand_history.ensureTotalCapacity(365);
        
        // Reset to initial values
        self.current_condition = .stable;
        self.base_oil_price = 50.0;
        self.current_oil_price = 50.0;
        self.global_demand = 100.0;
        self.global_supply = 101.0;
        self.volatility = 0.1;
        
        // Re-initialize competitors and events
        // (skipped for brevity, would duplicate the initialization code)
    }
    
    /// Simulate market changes for one day
    pub fn simulateDay(self: *MarketSimulation) !void {
        // Update active events
        for (self.active_events.items) |*event| {
            event.advanceDay();
        }
        
        // Remove expired events using a fixed buffer to avoid allocations
        var active_indices: [16]usize = undefined;
        var active_count: usize = 0;
        
        // Find indices of active events
        for (self.active_events.items, 0..) |event, idx| {
            if (event.isActive()) {
                if (active_count < active_indices.len) {
                    active_indices[active_count] = idx;
                    active_count += 1;
                }
            }
        }
        
        // Clear and rebuild active events list
        if (active_count < self.active_events.items.len) {
            var new_active_events = std.ArrayList(WorldEvent).init(self.arena.allocator());
            try new_active_events.ensureTotalCapacity(active_count);
            
            for (active_indices[0..active_count]) |idx| {
                try new_active_events.append(self.active_events.items[idx]);
            }
            
            // Replace the old list with the new one
            self.active_events.deinit();
            self.active_events = new_active_events;
        }
        
        // Chance for new event
        const event_chance = 0.03 * self.volatility;
        if (std.crypto.random.float(f32) < event_chance and self.possible_events.items.len > 0) {
            const event_index = std.crypto.random.intRangeLessThan(usize, 0, self.possible_events.items.len);
            var new_event = self.possible_events.items[event_index];
            new_event.is_active = true;
            new_event.days_active = 0;
            try self.active_events.append(new_event);
        }
        
        // Update competitors
        for (self.competitors.items) |*competitor| {
            competitor.simulateDay(self.current_condition, self.current_oil_price);
            self.global_supply += competitor.production_rate / 1_000_000.0; // Convert to millions of barrels
        }
        
        // Calculate supply-demand balance
        const supply_demand_ratio = self.global_supply / self.global_demand;
        
        // Determine market condition based on supply-demand ratio
        self.current_condition = if (supply_demand_ratio > 1.2) .crisis
            else if (supply_demand_ratio > 1.05) .recession
            else if (supply_demand_ratio < 0.95) .boom
            else .stable;
        
        // Base price fluctuation from supply-demand
        var price_change = (1.0 - supply_demand_ratio) * 10.0;
        
        // Add random noise based on volatility
        price_change += (std.crypto.random.float(f32) * 2.0 - 1.0) * self.volatility * 5.0;
        
        // Apply event modifiers
        var event_price_modifier: f32 = 1.0;
        var event_demand_modifier: f32 = 1.0;
        
        for (self.active_events.items) |event| {
            event_price_modifier *= event.price_impact;
            event_demand_modifier *= event.demand_impact;
        }
        
        // Update price
        self.current_oil_price = @max(10.0, self.current_oil_price * (1.0 + price_change / 100.0) * event_price_modifier);
        
        // Update demand with random walk + event modifiers
        const demand_change = (std.crypto.random.float(f32) * 2.0 - 1.0) * 2.0;
        self.global_demand = @max(10.0, self.global_demand * (1.0 + demand_change / 100.0) * event_demand_modifier);
        
        // Record history without checking size each time
        try self.price_history.append(self.current_oil_price);
        try self.demand_history.append(self.global_demand);
        
        // Use direct removal and ensure we don't check every day
        if (self.price_history.items.len > 365) {
            // Remove in batches to reduce operations
            const excess = self.price_history.items.len - 365;
            if (excess > 30) { // Only trim when we have a significant number to remove
                var i: usize = 0;
                while (i < excess) : (i += 1) {
                    _ = self.price_history.orderedRemove(0);
                }
            }
        }
        
        if (self.demand_history.items.len > 365) {
            // Remove in batches to reduce operations
            const excess = self.demand_history.items.len - 365;
            if (excess > 30) { // Only trim when we have a significant number to remove
                var i: usize = 0;
                while (i < excess) : (i += 1) {
                    _ = self.demand_history.orderedRemove(0);
                }
            }
        }
    }
    
    /// Get a list of active world events
    pub fn getActiveEvents(self: *const MarketSimulation) []const WorldEvent {
        return self.active_events.items;
    }
    
    /// Get the current market trend (up, down, or stable)
    pub fn getMarketTrend(self: *const MarketSimulation) []const u8 {
        if (self.price_history.items.len < 7) {
            return "Unknown";
        }
        
        const current = self.price_history.items[self.price_history.items.len - 1];
        const week_ago = self.price_history.items[self.price_history.items.len - 7];
        
        const percentage_change = (current - week_ago) / week_ago * 100.0;
        
        // Use comptime strings to avoid allocations
        return if (percentage_change > 5.0) 
            "Strong Upward"
        else if (percentage_change > 1.0) 
            "Upward"
        else if (percentage_change < -5.0) 
            "Strong Downward"
        else if (percentage_change < -1.0) 
            "Downward"
        else 
            "Stable";
    }
}; 