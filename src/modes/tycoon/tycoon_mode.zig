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

/// Corporate strategy that provides unique bonuses and abilities
pub const CorporateStrategy = struct {
    name: []const u8,
    description: []const u8,
    bonuses: []const []const u8,
    price_modifier: f32, // How this strategy affects oil prices
    production_modifier: f32, // How this strategy affects production
    reputation_modifier: f32, // How this strategy affects reputation
    tech_modifier: f32, // How this strategy affects technology advancement
    market_event_frequency_modifier: f32, // How this strategy affects random event frequency
    special_ability: SpecialAbility, // Unique ability that can be activated
    cooldown_days: u32, // Days before special ability can be used again
    current_cooldown: u32 = 0, // Current cooldown timer
    
    /// Get a color based on the strategy type
    pub fn getColor(self: *const CorporateStrategy) terminal_ui.TextColor {
        return switch (self.special_ability) {
            .market_manipulation => .bright_red,
            .technological_breakthrough => .bright_cyan,
            .aggressive_acquisition => .bright_yellow,
            .reputation_campaign => .bright_green,
            .crisis_management => .bright_magenta,
        };
    }
    
    /// Special abilities that can be triggered by the player
    pub const SpecialAbility = enum {
        market_manipulation, // Temporarily influence market prices
        technological_breakthrough, // Boost technology development
        aggressive_acquisition, // Forcefully acquire competitor assets
        reputation_campaign, // Launch PR campaign to improve reputation
        crisis_management, // Reduce impact of negative events
        
        /// Get description of the special ability
        pub fn getDescription(self: SpecialAbility) []const u8 {
            return switch (self) {
                .market_manipulation => "Manipulate oil prices by 25% in your favor for 5 days",
                .technological_breakthrough => "Double technology advancement speed for 10 days",
                .aggressive_acquisition => "Attempt hostile takeover of competitor assets",
                .reputation_campaign => "Launch major PR campaign to improve reputation by 15%",
                .crisis_management => "Reduce impact of all active negative events by 50%",
            };
        }
        
        /// Get the cooldown period for this ability in days
        pub fn getCooldown(self: SpecialAbility) u32 {
            return switch (self) {
                .market_manipulation => 30,
                .technological_breakthrough => 45,
                .aggressive_acquisition => 60,
                .reputation_campaign => 30,
                .crisis_management => 20,
            };
        }
    };
    
    /// Available company strategies
    pub const strategies = struct {
        pub const market_dominator = CorporateStrategy{
            .name = "Market Dominator",
            .description = "Focus on aggressive expansion and market control",
            .bonuses = &[_][]const u8{
                "Oil field acquisition costs reduced by 15%",
                "Production capacity increased by 20%",
                "Market share growth accelerated by 25%",
                "Competitor acquisition chance increased by 30%",
            },
            .price_modifier = 0.9, // Lower prices to gain market share
            .production_modifier = 1.2, // Higher production
            .reputation_modifier = 0.8, // Lower reputation focus
            .tech_modifier = 0.9, // Lower tech focus
            .market_event_frequency_modifier = 1.2, // More market volatility
            .special_ability = .aggressive_acquisition,
            .cooldown_days = 60,
        };
        
        pub const tech_innovator = CorporateStrategy{
            .name = "Technological Innovator",
            .description = "Lead the industry through advanced technology",
            .bonuses = &[_][]const u8{
                "Technology advancement speed increased by 40%",
                "Research costs reduced by 25%",
                "Production efficiency improved by 15%",
                "Environmental impact reduced by 30%",
            },
            .price_modifier = 1.05, // Premium prices due to efficiency
            .production_modifier = 0.9, // Lower initial production
            .reputation_modifier = 1.1, // Higher reputation
            .tech_modifier = 1.4, // Much higher tech focus
            .market_event_frequency_modifier = 0.9, // Less affected by market
            .special_ability = .technological_breakthrough,
            .cooldown_days = 45,
        };
        
        pub const market_manipulator = CorporateStrategy{
            .name = "Market Manipulator",
            .description = "Control the market through strategic manipulation",
            .bonuses = &[_][]const u8{
                "Oil price volatility works in your favor by 25%",
                "Market events provide 20% stronger benefits",
                "Strategic reserve allows withholding 30% production",
                "Market intelligence provides advance warning of price changes",
            },
            .price_modifier = 1.1, // Higher prices through manipulation
            .production_modifier = 1.0, // Standard production
            .reputation_modifier = 0.7, // Much lower reputation
            .tech_modifier = 1.0, // Standard tech
            .market_event_frequency_modifier = 1.3, // Much more market volatility
            .special_ability = .market_manipulation,
            .cooldown_days = 30,
        };
        
        pub const sustainable_developer = CorporateStrategy{
            .name = "Sustainable Developer",
            .description = "Build a sustainable and respected company",
            .bonuses = &[_][]const u8{
                "Reputation gain increased by 50%",
                "Environmental events have 70% less impact",
                "Technology focuses on sustainability, 25% more efficient",
                "Competitor relationship bonus of 20%",
            },
            .price_modifier = 1.15, // Premium prices for ethical oil
            .production_modifier = 0.8, // Lower production for sustainability
            .reputation_modifier = 1.5, // Much higher reputation focus
            .tech_modifier = 1.25, // Higher tech focus
            .market_event_frequency_modifier = 0.7, // Less affected by market
            .special_ability = .reputation_campaign,
            .cooldown_days = 30,
        };
        
        pub const crisis_expert = CorporateStrategy{
            .name = "Crisis Expert",
            .description = "Thrive in chaotic markets and crisis situations",
            .bonuses = &[_][]const u8{
                "Negative event impact reduced by 60%",
                "Company adapts 40% faster to market changes",
                "Field acquisition opportunities increase 30% during crises",
                "Reputation recovers 50% faster from negative events",
            },
            .price_modifier = 1.0, // Standard prices
            .production_modifier = 1.1, // Slightly higher production
            .reputation_modifier = 1.2, // Higher reputation resilience
            .tech_modifier = 1.1, // Slightly higher tech
            .market_event_frequency_modifier = 0.5, // Much less affected by market
            .special_ability = .crisis_management,
            .cooldown_days = 20,
        };
    };
    
    /// Activate special ability
    pub fn activateSpecialAbility(self: *CorporateStrategy, game: *TycoonMode) !bool {
        if (self.current_cooldown > 0) {
            return false; // Still on cooldown
        }
        
        self.current_cooldown = self.cooldown_days;
        
        switch (self.special_ability) {
            .market_manipulation => {
                // Manipulate oil prices in player's favor
                const direction = if (game.oil_price < game.base_oil_price) 1.25 else 0.75;
                game.market.applyPriceManipulation(direction, 5);
                return true;
            },
            .technological_breakthrough => {
                // Double tech advancement speed for 10 days
                game.tech_boost_days = 10;
                game.tech_boost_multiplier = 2.0;
                return true;
            },
            .aggressive_acquisition => {
                // Attempt hostile takeover of competitor assets
                return game.attemptHostileTakeover();
            },
            .reputation_campaign => {
                // Launch PR campaign
                game.company_reputation = @min(1.0, game.company_reputation + 0.15);
                // Create positive news event
                try game.market.addCustomEvent("PR Campaign", "Your company launches a massive PR campaign highlighting community initiatives.", 1.0, 1.0, 0.1, 7);
                return true;
            },
            .crisis_management => {
                // Reduce impact of active negative events
                game.crisis_management_days = 10;
                return true;
            },
        }
    }
    
    /// Update strategy cooldowns
    pub fn updateCooldown(self: *CorporateStrategy) void {
        if (self.current_cooldown > 0) {
            self.current_cooldown -= 1;
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
    
    // New fields for company strategy system
    active_strategy: ?*CorporateStrategy, // Currently active corporate strategy
    available_strategies: [5]CorporateStrategy, // Available strategies to choose from
    tech_boost_days: u32 = 0, // Days remaining for tech boost special ability
    tech_boost_multiplier: f32 = 1.0, // Multiplier for tech advancement
    crisis_management_days: u32 = 0, // Days remaining for crisis management
    
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
        
        // Add more research projects for depth
        try research_projects.append(ResearchProject{
            .name = "Deep Sea Drilling",
            .description = "Allows exploration of offshore oil fields with higher capacity",
            .cost = 120000.0,
            .duration_days = 40,
            .days_researched = 0,
            .completed = false,
        });
        
        try research_projects.append(ResearchProject{
            .name = "Automated Extraction",
            .description = "Reduces operating costs by 20% through automation",
            .cost = 85000.0,
            .duration_days = 35,
            .days_researched = 0,
            .completed = false,
        });
        
        try research_projects.append(ResearchProject{
            .name = "Market Prediction AI",
            .description = "Provides early warnings about market shifts",
            .cost = 100000.0,
            .duration_days = 30,
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
        
        // Initialize corporate strategies
        const strategies = [_]CorporateStrategy{
            CorporateStrategy.strategies.market_dominator,
            CorporateStrategy.strategies.tech_innovator,
            CorporateStrategy.strategies.market_manipulator,
            CorporateStrategy.strategies.sustainable_developer,
            CorporateStrategy.strategies.crisis_expert,
        };
        
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
            .active_strategy = null,
            .available_strategies = strategies,
            .allocator = allocator,
        };
    }
    
    /// Process a day in the tycoon mode
    pub fn advanceDay(self: *TycoonMode) !void {
        self.game_days += 1;
        
        // Update strategy cooldowns
        if (self.active_strategy) |strategy| {
            strategy.updateCooldown();
        }
        
        // Update tech boost
        if (self.tech_boost_days > 0) {
            self.tech_boost_days -= 1;
            if (self.tech_boost_days == 0) {
                self.tech_boost_multiplier = 1.0;
            }
        }
        
        // Update crisis management
        if (self.crisis_management_days > 0) {
            self.crisis_management_days -= 1;
        }
        
        // Update market simulation first
        try self.market.simulateDay();
        
        // Update market condition and oil price from market simulation
        self.market_condition = self.market.current_condition;
        self.oil_price = self.market.current_oil_price;
        
        // Apply strategy modifiers if active
        if (self.active_strategy) |strategy| {
            // Modify oil price based on strategy
            self.oil_price *= strategy.price_modifier;
        }
        
        // Calculate daily production from all fields
        var total_extracted: f32 = 0;
        var total_capacity: f32 = 0;
        
        for (self.oil_fields.items) |*field| {
            // Calculate extraction modified by department levels
            const production_modifier = 1.0 + @as(f32, @floatFromInt(self.department_levels[@intFromEnum(Department.production)])) * 0.1;
            
            // Apply strategy production modifier
            const strategy_production_modifier = if (self.active_strategy) |strategy|
                strategy.production_modifier
            else
                1.0;
            
            const extraction_rate = field.extraction_rate * field.quality * production_modifier * strategy_production_modifier;
            
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
        
        // Apply strategy price modifier
        const strategy_price_modifier = if (self.active_strategy) |strategy|
            strategy.price_modifier
        else
            1.0;
        
        const effective_price = self.oil_price * marketing_multiplier * strategy_price_modifier;
        
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
            
            // Apply tech boost multiplier if active
            const final_research_speed = research_speed * self.tech_boost_multiplier;
            
            // Apply strategy tech modifier
            const strategy_tech_modifier = if (self.active_strategy) |strategy|
                strategy.tech_modifier
            else
                1.0;
            
            const days_progress = @max(1, @as(u32, @intFromFloat(final_research_speed * strategy_tech_modifier)));
            
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
                } else if (std.mem.eql(u8, project.name, "Deep Sea Drilling")) {
                    // Generate offshore fields with higher capacity
                    try self.generateOffshoreFields(2);
                } else if (std.mem.eql(u8, project.name, "Automated Extraction")) {
                    // Reduce operating costs
                    self.operating_costs *= 0.8;
                } else if (std.mem.eql(u8, project.name, "Market Prediction AI")) {
                    // Enable market predictions
                    self.market.predictability_enabled = true;
                }
                
                // Show research completion message
                // This would typically be handled by the UI, but we'll set a flag here
                self.market.research_completed = true;
                self.market.last_completed_research = project.name;
            }
        }
        
        // Chance for reputation effects from world events
        for (self.market.active_events.items) |event| {
            // Apply strategy reputation modifier and crisis management
            var reputation_impact = event.reputation_impact;
            
            if (self.active_strategy) |strategy| {
                reputation_impact *= strategy.reputation_modifier;
            }
            
            // Reduce negative impacts if crisis management is active
            if (self.crisis_management_days > 0 and reputation_impact < 0) {
                reputation_impact *= 0.5; // 50% reduction
            }
            
            self.company_reputation += reputation_impact / @as(f32, @floatFromInt(event.duration_days));
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
        
        // Generate crisis events
        try self.checkForCrisisEvents();
    }

    /// Check for potential crisis events
    fn checkForCrisisEvents(self: *TycoonMode) !void {
        // Crisis events should be rare but impactful
        const base_crisis_chance = 0.01; // 1% daily chance
        
        // Adjust based on market condition
        var crisis_chance = switch (self.market_condition) {
            .boom => base_crisis_chance * 0.5,
            .stable => base_crisis_chance,
            .recession => base_crisis_chance * 2.0,
            .crisis => base_crisis_chance * 4.0,
        };
        
        // Adjust based on company size - larger companies attract more problems
        crisis_chance *= 1.0 + self.player_market_share;
        
        // Adjust based on reputation - higher reputation means fewer crises
        crisis_chance *= 2.0 - self.company_reputation;
        
        // Adjust based on strategy frequency modifier
        if (self.active_strategy) |strategy| {
            crisis_chance *= strategy.market_event_frequency_modifier;
        }
        
        // Check if crisis occurs
        if (std.crypto.random.float(f32) < crisis_chance) {
            // Select a crisis type
            const crisis_types = [_][]const u8{
                "Oil Spill Disaster",
                "Worker Strike",
                "Equipment Failure",
                "Government Investigation",
                "Activist Blockade",
                "Tax Audit",
                "Cyber Attack",
                "Executive Scandal",
                "Supply Chain Disruption",
            };
            
            const crisis_descriptions = [_][]const u8{
                "One of your oil fields has experienced a major spill, causing environmental damage.",
                "Workers have gone on strike demanding better conditions and pay.",
                "Critical equipment at multiple sites has failed simultaneously.",
                "Government regulators are investigating your business practices.",
                "Environmental activists have blockaded access to your facilities.",
                "Tax authorities are conducting a comprehensive audit of your finances.",
                "Your company's systems have been compromised in a cyber attack.",
                "A high-ranking executive is embroiled in a public scandal.",
                "Key suppliers have failed to deliver essential equipment and materials.",
            };
            
            const crisis_index = std.crypto.random.uintLessThan(usize, crisis_types.len);
            
            // Create the crisis event
            try self.market.addCustomEvent(
                crisis_types[crisis_index],
                crisis_descriptions[crisis_index],
                // Severe price impact (usually negative)
                0.85 + std.crypto.random.float(f32) * 0.2,
                // Reduce demand
                0.8 + std.crypto.random.float(f32) * 0.15,
                // Major reputation hit
                -0.2 - std.crypto.random.float(f32) * 0.1,
                // Last 7-14 days
                7 + std.crypto.random.uintLessThan(u32, 8)
            );
            
            // Apply immediate financial penalty
            const penalty = self.money * (0.05 + std.crypto.random.float(f32) * 0.1);
            self.money -= penalty;
            
            // Flag crisis for UI notification
            self.market.crisis_occurred = true;
            self.market.latest_crisis = crisis_types[crisis_index];
        }
    }
    
    /// Attempt hostile takeover of competitor assets
    fn attemptHostileTakeover(self: *TycoonMode) bool {
        // Must have substantial funds
        if (self.money < 1000000.0 or self.market.competitors.items.len == 0) {
            return false;
        }
        
        // Find the weakest competitor
        var weakest_index: usize = 0;
        var weakest_value: f32 = std.math.inf(f32);
        
        for (self.market.competitors.items, 0..) |competitor, i| {
            const competitor_value = competitor.production_rate * competitor.fields_owned * 10000.0;
            if (competitor_value < weakest_value) {
                weakest_value = competitor_value;
                weakest_index = i;
            }
        }
        
        // Calculate takeover cost - based on competitor size and a random factor
        const takeover_cost = weakest_value * (0.7 + std.crypto.random.float(f32) * 0.6);
        
        // Check if player can afford it
        if (self.money < takeover_cost) {
            return false;
        }
        
        // Deduct cost
        self.money -= takeover_cost;
        
        // Acquire some of their fields (convert to player fields)
        const fields_acquired = @max(1, self.market.competitors.items[weakest_index].fields_owned / 3);
        
        // Update competitor
        self.market.competitors.items[weakest_index].fields_owned -= fields_acquired;
        self.market.competitors.items[weakest_index].production_rate *= 0.7; // Big production hit
        self.market.competitors.items[weakest_index].size *= 0.8; // Market share decrease
        
        // Increase player fields by roughly equivalent fields
        for (0..fields_acquired) |_| {
            const field_size = 5000.0 + std.crypto.random.float(f32) * 10000.0;
            const field_rate = 10.0 + std.crypto.random.float(f32) * 15.0;
            var new_field = oil_field.OilField.init(field_size, field_rate);
            new_field.quality = 0.8 + std.crypto.random.float(f32) * 0.4;
            new_field.depth = 1.0 + std.crypto.random.float(f32) * 1.0;
            
            // Random depletion level
            new_field.oil_amount *= 0.5 + std.crypto.random.float(f32) * 0.5;
            
            self.oil_fields.append(new_field) catch {};
        }
        
        // Reputation hit for aggressive action
        self.company_reputation = @max(0.0, self.company_reputation - 0.1);
        
        // Create market event for the takeover
        self.market.addCustomEvent(
            "Hostile Takeover",
            "Your company has executed a hostile takeover of competitor assets.",
            1.05, // Slight price increase due to market concentration
            1.0, // Neutral demand impact
            -0.05, // Small reputation hit
            14 // Two-week news cycle
        ) catch {};
        
        return true;
    }
    
    /// Generate offshore oil fields (higher capacity but more expensive)
    fn generateOffshoreFields(self: *TycoonMode, count: usize) !void {
        var i: usize = 0;
        while (i < count) : (i += 1) {
            // Offshore fields are larger but more expensive
            const size_factor = 1.5 + std.crypto.random.float(f32) * 1.5; // 1.5 to 3.0
            const size = 10000.0 + size_factor * 5000.0;
            
            // Random extraction rate
            const rate_factor = std.crypto.random.float(f32) + 0.8; // 0.8 to 1.8
            const rate = 8.0 + rate_factor * 8.0;
            
            var new_field = oil_field.OilField.init(size, rate);
            
            // Offshore fields have higher quality
            const quality_factor = std.crypto.random.float(f32) * 0.3 + 1.0; // 1.0 to 1.3
            new_field.quality = quality_factor;
            
            // Offshore fields are deeper
            const depth_factor = std.crypto.random.float(f32) * 1.0 + 2.0; // 2.0 to 3.0
            new_field.depth = depth_factor;
            
            // Mark as offshore for UI visualization
            new_field.is_offshore = true;
            
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

/// Decision event presented to the player
pub const DecisionEvent = struct {
    title: []const u8,
    description: []const u8,
    choices: [3]Choice, // Always 3 choices for consistency
    shown: bool = false,
    
    /// A choice the player can make
    pub const Choice = struct {
        text: []const u8,
        money_impact: f32,
        reputation_impact: f32,
        production_impact: f32,
        market_impact: f32,
        special_effect: ?SpecialEffect = null,
        
        /// Special effects that can impact the game
        pub const SpecialEffect = enum {
            improve_field_quality,
            reduce_operating_costs,
            attract_new_investors,
            unlock_research_project,
            competitor_backlash,
            
            pub fn getDescription(self: SpecialEffect) []const u8 {
                return switch (self) {
                    .improve_field_quality => "Your engineers improve oil field quality by 10%",
                    .reduce_operating_costs => "You optimize operations, reducing costs by 5%",
                    .attract_new_investors => "New investors provide a capital infusion",
                    .unlock_research_project => "You gain access to a new research project",
                    .competitor_backlash => "Competitors retaliate against your actions",
                };
            }
        };
    };
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
    
    // Flags for UI notifications
    crisis_occurred: bool = false,
    latest_crisis: []const u8 = "",
    research_completed: bool = false,
    last_completed_research: []const u8 = "",
    predictability_enabled: bool = false, // Unlocked by Market Prediction AI research
    
    // New fields for decision events
    decision_events: std.ArrayList(DecisionEvent),
    current_decision: ?*DecisionEvent = null,
    decision_pending: bool = false,
    daily_decision_chance: f32 = 0.2, // 20% chance per day
    
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
        const decision_events = std.ArrayList(DecisionEvent).init(arena_allocator);
        
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
        
        // Initialize decision events
        try initializeDecisionEvents(&decision_events);
        
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
            .decision_events = decision_events,
            .arena = arena,
            .parent_allocator = allocator,
        };
    }
    
    /// Initialize all decision events
    fn initializeDecisionEvents(events: *std.ArrayList(DecisionEvent)) !void {
        // Decision 1: Drilling rights negotiation
        try events.append(DecisionEvent{
            .title = "Drilling Rights Negotiation",
            .description = "A local government official approaches you about acquiring drilling rights in a promising region, but they're expecting some 'cooperation'.",
            .choices = [_]DecisionEvent.Choice{
                .{
                    .text = "Pay the requested 'facilitation fee' to secure the rights",
                    .money_impact = -50000.0,
                    .reputation_impact = -0.05,
                    .production_impact = 0.15,
                    .market_impact = 0.0,
                    .special_effect = .improve_field_quality,
                },
                .{
                    .text = "Negotiate through official channels only",
                    .money_impact = -20000.0,
                    .reputation_impact = 0.05,
                    .production_impact = 0.05,
                    .market_impact = 0.0,
                    .special_effect = null,
                },
                .{
                    .text = "Decline and look elsewhere",
                    .money_impact = 0.0,
                    .reputation_impact = 0.0,
                    .production_impact = 0.0,
                    .market_impact = 0.0,
                    .special_effect = null,
                },
            },
        });
        
        // Decision 2: Environmental regulations
        try events.append(DecisionEvent{
            .title = "Environmental Regulations",
            .description = "New environmental regulations are being discussed that would increase your operating costs. You have an opportunity to lobby against them.",
            .choices = [_]DecisionEvent.Choice{
                .{
                    .text = "Aggressively lobby against the regulations",
                    .money_impact = -75000.0,
                    .reputation_impact = -0.1,
                    .production_impact = 0.0,
                    .market_impact = 0.02,
                    .special_effect = null,
                },
                .{
                    .text = "Invest in more environmentally friendly technology",
                    .money_impact = -100000.0,
                    .reputation_impact = 0.15,
                    .production_impact = -0.05,
                    .market_impact = 0.0,
                    .special_effect = .reduce_operating_costs,
                },
                .{
                    .text = "Adapt to the new regulations without resistance",
                    .money_impact = -30000.0,
                    .reputation_impact = 0.05,
                    .production_impact = -0.03,
                    .market_impact = 0.0,
                    .special_effect = null,
                },
            },
        });
        
        // Decision 3: Competitor takeover
        try events.append(DecisionEvent{
            .title = "Competitor Acquisition Opportunity",
            .description = "A smaller competitor is struggling and could be acquired at a favorable price. However, this might trigger scrutiny from regulators.",
            .choices = [_]DecisionEvent.Choice{
                .{
                    .text = "Aggressively pursue the acquisition",
                    .money_impact = -500000.0,
                    .reputation_impact = -0.05,
                    .production_impact = 0.2,
                    .market_impact = 0.03,
                    .special_effect = .competitor_backlash,
                },
                .{
                    .text = "Offer a strategic partnership instead",
                    .money_impact = -200000.0,
                    .reputation_impact = 0.05,
                    .production_impact = 0.1,
                    .market_impact = 0.01,
                    .special_effect = null,
                },
                .{
                    .text = "Decline the opportunity",
                    .money_impact = 0.0,
                    .reputation_impact = 0.0,
                    .production_impact = 0.0,
                    .market_impact = 0.0,
                    .special_effect = null,
                },
            },
        });
        
        // Decision 4: Research breakthrough
        try events.append(DecisionEvent{
            .title = "Research Breakthrough",
            .description = "Your R&D team has made a breakthrough that could be developed in different directions.",
            .choices = [_]DecisionEvent.Choice{
                .{
                    .text = "Focus on extraction efficiency",
                    .money_impact = -150000.0,
                    .reputation_impact = 0.0,
                    .production_impact = 0.15,
                    .market_impact = 0.0,
                    .special_effect = .improve_field_quality,
                },
                .{
                    .text = "Focus on cost reduction",
                    .money_impact = -150000.0,
                    .reputation_impact = 0.0,
                    .production_impact = 0.0,
                    .market_impact = 0.0,
                    .special_effect = .reduce_operating_costs,
                },
                .{
                    .text = "Focus on environmental impact",
                    .money_impact = -150000.0,
                    .reputation_impact = 0.15,
                    .production_impact = 0.0,
                    .market_impact = 0.0,
                    .special_effect = .unlock_research_project,
                },
            },
        });
        
        // Decision 5: Investment round
        try events.append(DecisionEvent{
            .title = "Investor Interest",
            .description = "Investors are showing interest in your company. How will you approach this opportunity?",
            .choices = [_]DecisionEvent.Choice{
                .{
                    .text = "Seek maximum investment by promising aggressive growth",
                    .money_impact = 1000000.0,
                    .reputation_impact = -0.05,
                    .production_impact = 0.0,
                    .market_impact = 0.02,
                    .special_effect = .attract_new_investors,
                },
                .{
                    .text = "Balance growth promises with sustainable practices",
                    .money_impact = 500000.0,
                    .reputation_impact = 0.05,
                    .production_impact = 0.0,
                    .market_impact = 0.01,
                    .special_effect = null,
                },
                .{
                    .text = "Maintain current ownership structure",
                    .money_impact = 0.0,
                    .reputation_impact = 0.0,
                    .production_impact = 0.0,
                    .market_impact = 0.0,
                    .special_effect = null,
                },
            },
        });
    }
    
    /// Select a random decision event to present to the player
    pub fn selectRandomDecision(self: *MarketSimulation) bool {
        // Only trigger if no decision is pending
        if (self.decision_pending) {
            return false;
        }
        
        // Don't show decisions too frequently
        if (std.crypto.random.float(f32) > self.daily_decision_chance) {
            return false;
        }
        
        // Find unshown decisions
        var available_decisions = std.ArrayList(*DecisionEvent).init(self.arena.allocator());
        defer available_decisions.deinit();
        
        for (self.decision_events.items) |*event| {
            if (!event.shown) {
                available_decisions.append(event) catch return false;
            }
        }
        
        // If all decisions have been shown, reset them
        if (available_decisions.items.len == 0) {
            for (self.decision_events.items) |*event| {
                event.shown = false;
            }
            
            // Try again
            return self.selectRandomDecision();
        }
        
        // Select a random decision
        const random_index = std.crypto.random.uintLessThan(usize, available_decisions.items.len);
        self.current_decision = available_decisions.items[random_index];
        self.decision_pending = true;
        
        return true;
    }
    
    /// Add a custom world event - useful for crisis events and special abilities
    pub fn addCustomEvent(self: *MarketSimulation, name: []const u8, description: []const u8, price_impact: f32, demand_impact: f32, reputation_impact: f32, duration_days: u32) !void {
        try self.active_events.append(WorldEvent{
            .name = name,
            .description = description,
            .price_impact = price_impact,
            .demand_impact = demand_impact,
            .reputation_impact = reputation_impact,
            .duration_days = duration_days,
            .days_active = 0,
            .is_active = true,
        });
    }
    
    /// Apply price manipulation for the market manipulation special ability
    pub fn applyPriceManipulation(self: *MarketSimulation, direction: f32, days: u32) void {
        self.addCustomEvent(
            "Market Manipulation",
            "Your company has executed strategic price manipulation tactics.",
            direction, // Price multiplier
            1.0, // No impact on demand
            -0.02, // Small reputation hit
            days
        ) catch {};
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
        self.decision_events = std.ArrayList(DecisionEvent).init(arena_allocator);
        
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
        self.decision_pending = false;
        self.current_decision = null;
        
        // Reset UI flags
        self.crisis_occurred = false;
        self.latest_crisis = "";
        self.research_completed = false;
        self.last_completed_research = "";
        self.predictability_enabled = false;
    }
    
    /// Apply the effects of a decision choice
    pub fn applyDecisionChoice(self: *MarketSimulation, game: *TycoonMode, choice_index: usize) void {
        if (self.current_decision == null or !self.decision_pending) {
            return;
        }
        
        const decision = self.current_decision.?;
        if (choice_index >= decision.choices.len) {
            return;
        }
        
        const choice = decision.choices[choice_index];
        
        // Apply impacts
        game.money += choice.money_impact;
        game.company_reputation = @min(1.0, @max(0.0, game.company_reputation + choice.reputation_impact));
        
        // If production impact, apply to all fields
        if (choice.production_impact != 0.0) {
            for (game.oil_fields.items) |*field| {
                field.extraction_rate *= (1.0 + choice.production_impact);
            }
        }
        
        // Market impact affects price and volatility
        if (choice.market_impact != 0.0) {
            self.current_oil_price *= (1.0 + choice.market_impact);
            self.volatility = @min(0.5, self.volatility + choice.market_impact);
        }
        
        // Apply special effects
        if (choice.special_effect) |effect| {
            switch (effect) {
                .improve_field_quality => {
                    for (game.oil_fields.items) |*field| {
                        field.quality *= 1.1; // 10% quality improvement
                    }
                },
                .reduce_operating_costs => {
                    game.operating_costs *= 0.95; // 5% cost reduction
                },
                .attract_new_investors => {
                    // Already handled by the money impact, but could add additional effects
                    game.company_value *= 1.1; // Boost company valuation
                },
                .unlock_research_project => {
                    // Add a new research project
                    game.research_projects.append(ResearchProject{
                        .name = "Advanced Environmental Technologies",
                        .description = "Cutting-edge environmental protection systems that boost reputation",
                        .cost = 120000.0,
                        .duration_days = 45,
                        .days_researched = 0,
                        .completed = false,
                    }) catch {};
                },
                .competitor_backlash => {
                    // Competitors become more aggressive
                    for (self.competitors.items) |*competitor| {
                        competitor.aggressiveness = @min(1.0, competitor.aggressiveness + 0.1);
                    }
                    
                    // Add a negative event
                    self.addCustomEvent(
                        "Industry Backlash",
                        "Competitors have united against your aggressive tactics.",
                        0.95, // Price impact
                        0.95, // Demand impact
                        -0.05, // Reputation impact
                        14 // Duration
                    ) catch {};
                },
            }
        }
        
        // Mark the decision as shown
        decision.shown = true;
        self.decision_pending = false;
        self.current_decision = null;
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
        
        // Select a random decision if appropriate
        _ = self.selectRandomDecision();
        
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