const std = @import("std");
const oil_field = @import("oil_field.zig");
const engine = @import("simulation.zig");

/// Structure representing a mission in the campaign
pub const Mission = struct {
    id: usize,
    title: []const u8,
    description: []const u8,
    target_oil: f32, // Oil extraction target
    target_money: f32, // Money target
    time_limit: f32, // Time limit in days (if applicable)
    unlocked: bool,
    completed: bool,
    
    /// Check if mission is complete based on simulation state
    pub fn isComplete(self: *const Mission, sim: *const engine.SimulationEngine) bool {
        if (self.target_oil > 0 and sim.total_extracted < self.target_oil) {
            return false;
        }
        
        if (self.target_money > 0 and sim.money < self.target_money) {
            return false;
        }
        
        return true;
    }
};

/// Structure representing the campaign mode
pub const CampaignMode = struct {
    simulation: engine.SimulationEngine,
    missions: std.ArrayList(Mission),
    current_mission_id: usize,
    player_name: []const u8,
    company_name: []const u8,
    game_days: usize,
    allocator: std.mem.Allocator,
    
    /// Initialize a new campaign
    pub fn init(allocator: std.mem.Allocator, player_name: []const u8, company_name: []const u8) !CampaignMode {
        var sim = try engine.SimulationEngine.init(allocator);
        
        var missions = std.ArrayList(Mission).init(allocator);
        
        // Create initial mission
        const mission1 = Mission{
            .id = 1,
            .title = "First Steps",
            .description = "Extract 100 barrels of oil and earn $15,000.",
            .target_oil = 100.0,
            .target_money = 15000.0,
            .time_limit = 0, // No time limit
            .unlocked = true,
            .completed = false,
        };
        
        try missions.append(mission1);
        
        // Add starting oil field
        const starter_field = oil_field.OilField.init(1000.0, 5.0);
        try sim.addOilField(starter_field);
        
        return CampaignMode{
            .simulation = sim,
            .missions = missions,
            .current_mission_id = 1,
            .player_name = player_name,
            .company_name = company_name,
            .game_days = 0,
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *CampaignMode) void {
        self.simulation.deinit();
        self.missions.deinit();
    }
    
    /// Advance the game by one day
    pub fn advanceDay(self: *CampaignMode) !void {
        try self.simulation.step(1.0);
        self.game_days += 1;
        
        // Check mission completion
        if (self.current_mission_id <= self.missions.items.len) {
            var current_mission = &self.missions.items[self.current_mission_id - 1];
            
            if (!current_mission.completed and current_mission.isComplete(&self.simulation)) {
                current_mission.completed = true;
                
                // Unlock next mission if available
                if (self.current_mission_id < self.missions.items.len) {
                    self.missions.items[self.current_mission_id].unlocked = true;
                    self.current_mission_id += 1;
                }
            }
        }
    }
    
    /// Get the current mission
    pub fn getCurrentMission(self: *const CampaignMode) ?*const Mission {
        if (self.current_mission_id <= self.missions.items.len) {
            return &self.missions.items[self.current_mission_id - 1];
        }
        return null;
    }
}; 