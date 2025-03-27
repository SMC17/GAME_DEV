const std = @import("std");
const oil_field = @import("oil_field");

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
    allocator: std.mem.Allocator,
    
    /// Initialize a new tycoon mode
    pub fn init(allocator: std.mem.Allocator) !TycoonMode {
        var mode = TycoonMode{
            .oil_fields = std.ArrayList(oil_field.OilField).init(allocator),
            .available_fields = std.ArrayList(oil_field.OilField).init(allocator),
            .money = 500000.0, // Starting capital
            .company_value = 500000.0,
            .market_condition = .stable,
            .oil_price = 50.0,
            .base_oil_price = 50.0,
            .operating_costs = 5000.0, // Daily costs
            .research_projects = std.ArrayList(ResearchProject).init(allocator),
            .active_research = null,
            .department_levels = [_]u32{1} ** 5, // All departments start at level 1
            .company_reputation = 0.5, // Neutral reputation
            .game_days = 0,
            .allocator = allocator,
        };
        
        // Add initial research projects
        try mode.research_projects.append(ResearchProject{
            .name = "Advanced Drilling",
            .description = "Improves drilling efficiency by 15%",
            .cost = 75000.0,
            .duration_days = 30,
            .days_researched = 0,
            .completed = false,
        });
        
        try mode.research_projects.append(ResearchProject{
            .name = "Environmental Protection",
            .description = "Reduces environmental impact and improves reputation",
            .cost = 50000.0,
            .duration_days = 20,
            .days_researched = 0,
            .completed = false,
        });
        
        try mode.research_projects.append(ResearchProject{
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
        try mode.available_fields.append(field1);
        
        var field2 = oil_field.OilField.init(12000.0, 8.0);
        field2.quality = 1.1;
        field2.depth = 1.5;
        try mode.available_fields.append(field2);
        
        var field3 = oil_field.OilField.init(8000.0, 12.0);
        field3.quality = 0.9;
        field3.depth = 1.0;
        try mode.available_fields.append(field3);
        
        return mode;
    }
    
    /// Clean up resources
    pub fn deinit(self: *TycoonMode) void {
        self.oil_fields.deinit();
        self.available_fields.deinit();
        self.research_projects.deinit();
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
        // Calculate profit
        const daily_profit = self.calculateDailyProfit();
        self.money += daily_profit;
        
        // Update company value
        self.company_value = self.calculateCompanyValue();
        
        // Progress active research
        if (self.active_research) |project| {
            const research_level = self.department_levels[@intFromEnum(Department.research)];
            const research_speed = 1.0 + (0.1 * @as(f32, @floatFromInt(research_level - 1)));
            
            // Advance research faster with higher research department level
            var days_to_advance: u32 = 1;
            if (research_speed > 1.5) days_to_advance = 2;
            if (research_speed > 2.0) days_to_advance = 3;
            
            // Apply multiple days of research progress
            var i: u32 = 0;
            while (i < days_to_advance) : (i += 1) {
                project.advanceResearch();
                
                // Check if project completed
                if (project.completed) {
                    self.active_research = null;
                    
                    // Apply research benefits
                    if (std.mem.eql(u8, project.name, "Advanced Drilling")) {
                        // Improve extraction rate for all fields
                        for (self.oil_fields.items) |*field| {
                            field.quality *= 1.15;
                        }
                    } else if (std.mem.eql(u8, project.name, "Environmental Protection")) {
                        // Improve company reputation
                        self.company_reputation += 0.1;
                        if (self.company_reputation > 1.0) self.company_reputation = 1.0;
                    } else if (std.mem.eql(u8, project.name, "Oil Quality Analysis")) {
                        // Benefit will be applied in generateNewOilField
                    }
                    
                    break;
                }
            }
        }
        
        // Update market conditions
        self.updateMarketConditions();
        
        // Sometimes generate new oil fields to purchase
        if (self.game_days % 15 == 0 and self.available_fields.items.len < 5) {
            try self.generateNewOilField();
        }
        
        self.game_days += 1;
    }
}; 