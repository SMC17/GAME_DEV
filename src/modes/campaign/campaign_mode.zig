const std = @import("std");
const engine = @import("simulation");
const player_data = @import("player_data");

/// Different types of mission objectives
pub const MissionObjectiveType = enum {
    extract_oil,      // Extract a certain amount of oil
    earn_money,       // Earn a specific amount of money
    upgrade_equipment, // Upgrade drilling equipment
    hire_workers,     // Hire a number of workers
    time_constraint,  // Complete within a time limit
    build_reputation, // Build reputation to a certain level
    discover_field,   // Discover a new oil field
    research_tech,    // Research a specific technology
    environmental,    // Maintain environmental standards
    compete_market,   // Compete in the market (beat a competitor)
    diplomacy,        // Build relationships with specific characters
    crisis_management, // Handle a crisis situation
};

/// Mission difficulty levels affecting rewards and challenge
pub const MissionDifficulty = enum {
    tutorial,
    easy,
    medium,
    hard,
    expert,
    
    pub fn getMultiplier(self: MissionDifficulty) f32 {
        return switch (self) {
            .tutorial => 0.5,
            .easy => 1.0,
            .medium => 1.5,
            .hard => 2.0,
            .expert => 3.0,
        };
    }
};

/// Environmental impact constraints for missions
pub const EnvironmentalConstraint = struct {
    max_pollution: f32 = 100.0,
    requires_cleanup: bool = false,
    requires_green_tech: bool = false,
};

/// A structure representing mission rewards
pub const MissionReward = struct {
    money_bonus: f32 = 0,
    equipment_bonus: ?[]const u8 = null,
    new_oil_field: bool = false,
    reputation_increase: f32 = 0,
    technology_unlock: ?[]const u8 = null,
    staff_bonus: ?usize = null,
    special_contract: ?[]const u8 = null,
    
    /// Scale rewards based on difficulty
    pub fn scaledByDifficulty(self: MissionReward, difficulty: MissionDifficulty) MissionReward {
        const multiplier = difficulty.getMultiplier();
        return MissionReward{
            .money_bonus = self.money_bonus * multiplier,
            .equipment_bonus = self.equipment_bonus,
            .new_oil_field = self.new_oil_field,
            .reputation_increase = self.reputation_increase * multiplier,
            .technology_unlock = self.technology_unlock,
            .staff_bonus = self.staff_bonus,
            .special_contract = self.special_contract,
        };
    }
};

/// A structure representing a mission
pub const Mission = struct {
    id: usize,
    title: []const u8,
    description: []const u8,
    difficulty: MissionDifficulty = .medium,
    story_text: ?[]const u8 = null,
    
    // Mission objectives
    objective_type: MissionObjectiveType = .extract_oil,
    target_oil: f32 = 0,
    target_money: f32 = 0,
    target_equipment_level: usize = 0,
    target_workers: usize = 0,
    target_reputation: f32 = 0,
    target_tech: ?[]const u8 = null,
    target_competitor: ?[]const u8 = null,
    target_character: ?[]const u8 = null,
    target_relationship_level: f32 = 0,
    
    // Mission constraints
    environmental_constraints: ?EnvironmentalConstraint = null,
    market_condition_requirements: ?[]const []const u8 = null,
    
    // Time constraint (0 means no time limit)
    time_limit: usize = 0,
    start_day: usize = 0,
    
    // Mission state
    unlocked: bool = false,
    completed: bool = false,
    failed: bool = false,
    
    // Reward for completing the mission
    reward: MissionReward = .{},
    
    // Dependencies - missions that must be completed before this one unlocks
    dependencies: ?[]const usize = null,
    
    // Optional fields for branching missions
    branches_to: ?[]const usize = null,
    
    /// Check if the mission is completed based on the current state of the simulation
    pub fn isComplete(self: *const Mission) bool {
        if (player_data.getGlobalPlayerData()) |data| {
            return switch (self.objective_type) {
                .extract_oil => data.oil_extracted >= self.target_oil,
                .earn_money => data.money >= self.target_money,
                // Other objective types would need to be implemented based on game state
                .upgrade_equipment => false, // Placeholder
                .hire_workers => false, // Placeholder
                .time_constraint => false, // Handled separately
                .build_reputation => false, // Handled separately
                .discover_field => false, // Placeholder
                .research_tech => false, // Placeholder 
                .environmental => false, // Placeholder
                .compete_market => false, // Placeholder
                .diplomacy => false, // Placeholder
                .crisis_management => false, // Placeholder
            };
        }
        return false;
    }
    
    /// Check if the mission has failed based on time constraints
    pub fn isFailed(self: *const Mission, current_day: usize) bool {
        // If there's no time limit, the mission can't fail due to time
        if (self.time_limit == 0) return false;
        
        // If the mission hasn't started yet, it can't have failed
        if (self.start_day == 0) return false;
        
        // Check if the time limit has been exceeded
        const days_passed = current_day - self.start_day;
        return days_passed > self.time_limit;
    }
};

/// The campaign mode structure
pub const CampaignMode = struct {
    simulation: *engine.SimulationEngine,
    missions: std.ArrayList(Mission),
    current_mission: usize = 0,
    allocator: std.mem.Allocator,
    completed_missions: std.ArrayList(usize),
    failed_missions: std.ArrayList(usize),
    
    /// Initialize the campaign mode
    pub fn init(allocator: std.mem.Allocator) !CampaignMode {
        var simulation = try allocator.create(engine.SimulationEngine);
        errdefer allocator.destroy(simulation);
        
        simulation.* = try engine.SimulationEngine.init(allocator);
        errdefer simulation.deinit();
        
        var missions = std.ArrayList(Mission).init(allocator);
        errdefer missions.deinit();
        
        var completed_missions = std.ArrayList(usize).init(allocator);
        errdefer completed_missions.deinit();
        
        var failed_missions = std.ArrayList(usize).init(allocator);
        errdefer failed_missions.deinit();
        
        // Initialize with a campaign of missions
        try createCampaignMissions(&missions);
        
        // First mission is unlocked by default
        if (missions.items.len > 0) {
            missions.items[0].unlocked = true;
        }
        
        return CampaignMode{
            .simulation = simulation,
            .missions = missions,
            .allocator = allocator,
            .completed_missions = completed_missions,
            .failed_missions = failed_missions,
        };
    }
    
    /// Create a series of missions that form a campaign
    fn createCampaignMissions(missions: *std.ArrayList(Mission)) !void {
        // Mission 1: First Steps
        try missions.append(.{
            .id = 1,
            .title = "First Steps",
            .description = "Extract your first barrels of oil and begin building your company.",
            .objective_type = .extract_oil,
            .target_oil = 100.0,
            .reward = .{
                .money_bonus = 5000.0,
                .reputation_increase = 5.0,
            },
        });
        
        // Mission 2: Building Capital
        try missions.append(.{
            .id = 2,
            .title = "Building Capital",
            .description = "Accumulate funds to expand your operations.",
            .objective_type = .earn_money,
            .target_money = 25000.0,
            .reward = .{
                .new_oil_field = true,
                .reputation_increase = 10.0,
            },
            .dependencies = &[_]usize{1},
        });
        
        // Mission 3: Expansion
        try missions.append(.{
            .id = 3,
            .title = "Expansion",
            .description = "Expand your operations by extracting more oil from your fields.",
            .objective_type = .extract_oil,
            .target_oil = 500.0,
            .reward = .{
                .money_bonus = 15000.0,
                .equipment_bonus = "Advanced Drilling Equipment",
            },
            .dependencies = &[_]usize{2},
        });
        
        // Mission 4: Market Dominance
        try missions.append(.{
            .id = 4,
            .title = "Market Dominance",
            .description = "Establish yourself as a major player in the oil market.",
            .objective_type = .earn_money,
            .target_money = 100000.0,
            .time_limit = 30, // Days to complete
            .reward = .{
                .money_bonus = 50000.0,
                .new_oil_field = true,
                .reputation_increase = 25.0,
            },
            .dependencies = &[_]usize{3},
        });
        
        // Mission 5: Industry Leader
        try missions.append(.{
            .id = 5,
            .title = "Industry Leader",
            .description = "Become the largest oil producer in the region.",
            .objective_type = .extract_oil,
            .target_oil = 2000.0,
            .reward = .{
                .money_bonus = 100000.0,
                .equipment_bonus = "State-of-the-Art Extraction System",
                .reputation_increase = 50.0,
            },
            .dependencies = &[_]usize{4},
        });
    }
    
    /// Clean up resources
    pub fn deinit(self: *CampaignMode) void {
        self.simulation.deinit();
        self.allocator.destroy(self.simulation);
        self.missions.deinit();
    }
    
    /// Advance the game by one day
    pub fn advanceDay(self: *CampaignMode) void {
        // Note: The SimulationEngine doesn't have an advanceDay method
        // We'll add a step call instead with a time delta of 1.0
        self.simulation.step(1.0) catch {};
        
        // Record current mission start day if it hasn't been set
        if (self.getCurrentMission()) |mission| {
            if (mission.start_day == 0) {
                for (self.missions.items) |*m| {
                    if (m.id == self.current_mission) {
                        m.start_day = @as(usize, @intFromFloat(self.simulation.time_elapsed));
                        break;
                    }
                }
            }
        }
        
        // Check if any missions have failed due to time constraints
        for (self.missions.items) |*mission| {
            if (mission.unlocked and !mission.completed and !mission.failed) {
                if (mission.isFailed(@as(usize, @intFromFloat(self.simulation.time_elapsed)))) {
                    mission.failed = true;
                    self.failed_missions.append(mission.id) catch {};
                }
            }
        }
    }
    
    /// Get the current mission
    pub fn getCurrentMission(self: *const CampaignMode) ?*const Mission {
        for (self.missions.items) |*mission| {
            if (mission.id == self.current_mission) {
                return mission;
            }
        }
        return null;
    }
    
    /// Check if the current mission is completed
    pub fn checkMissionCompletion(self: *CampaignMode) bool {
        for (self.missions.items) |*mission| {
            if (mission.id == self.current_mission and !mission.completed) {
                const is_complete = mission.isComplete();
                
                // Also check time constraint if applicable
                var time_constraint_passed = true;
                if (mission.time_limit > 0) {
                    const days_passed = @as(usize, @intFromFloat(self.simulation.time_elapsed)) - mission.start_day;
                    time_constraint_passed = days_passed <= mission.time_limit;
                }
                
                if (is_complete and time_constraint_passed) {
                    mission.completed = true;
                    self.completed_missions.append(mission.id) catch {};
                    return true;
                }
            }
        }
        return false;
    }
    
    /// Unlock missions based on completed dependencies
    pub fn unlockMissions(self: *CampaignMode) void {
        for (self.missions.items) |*mission| {
            // Skip already unlocked missions
            if (mission.unlocked) continue;
            
            // Check dependencies
            if (mission.dependencies) |deps| {
                var all_deps_completed = true;
                
                for (deps) |dep_id| {
                    var dep_completed = false;
                    
                    // Find the dependency mission and check if completed
                    for (self.missions.items) |dep_mission| {
                        if (dep_mission.id == dep_id) {
                            dep_completed = dep_mission.completed;
                            break;
                        }
                    }
                    
                    if (!dep_completed) {
                        all_deps_completed = false;
                        break;
                    }
                }
                
                // Unlock if all dependencies are completed
                if (all_deps_completed) {
                    mission.unlocked = true;
                }
            } else {
                // No dependencies, unlock by default
                mission.unlocked = true;
            }
        }
        
        // If current mission is completed, select the next unlocked mission
        if (self.getCurrentMission()) |current| {
            if (current.completed) {
                // Find the next unlocked and not completed mission
                for (self.missions.items) |mission| {
                    if (mission.unlocked and !mission.completed) {
                        self.current_mission = mission.id;
                        break;
                    }
                }
            }
        }
    }
}; 