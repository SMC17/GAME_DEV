const std = @import("std");

/// Stores all shared player progression across game modes
pub const PlayerData = struct {
    // Character progress
    character_level: u32,
    management_skill: f32, // 0.0-10.0
    engineering_skill: f32, // 0.0-10.0
    negotiation_skill: f32, // 0.0-10.0
    exploration_skill: f32, // 0.0-10.0
    environmental_skill: f32, // 0.0-10.0
    
    // Tycoon progress
    company_reputation: f32, // 0.0-100.0
    total_earnings: f64,
    largest_oilfield_size: f64,
    company_value: f64,
    
    // Campaign progress
    completed_missions: std.StringHashMap(bool),
    discovered_regions: std.StringHashMap(bool),
    
    // Sandbox unlocks
    unlocked_scenarios: std.StringHashMap(bool),
    unlocked_regions: std.StringHashMap(bool),
    
    // Arcade progress
    high_scores: std.StringHashMap(u64),
    unlocked_arcade_features: std.StringHashMap(bool),
    
    // Achievement tracking
    achievements: std.StringHashMap(bool),
    
    // Allocator for hashmaps
    allocator: std.mem.Allocator,
    
    /// Initialize new player data
    pub fn init(allocator: std.mem.Allocator) !PlayerData {
        var data = PlayerData{
            .character_level = 1,
            .management_skill = 1.0,
            .engineering_skill = 1.0,
            .negotiation_skill = 1.0,
            .exploration_skill = 1.0,
            .environmental_skill = 1.0,
            
            .company_reputation = 50.0,
            .total_earnings = 0,
            .largest_oilfield_size = 0,
            .company_value = 10000,
            
            .completed_missions = std.StringHashMap(bool).init(allocator),
            .discovered_regions = std.StringHashMap(bool).init(allocator),
            
            .unlocked_scenarios = std.StringHashMap(bool).init(allocator),
            .unlocked_regions = std.StringHashMap(bool).init(allocator),
            
            .high_scores = std.StringHashMap(u64).init(allocator),
            .unlocked_arcade_features = std.StringHashMap(bool).init(allocator),
            
            .achievements = std.StringHashMap(bool).init(allocator),
            
            .allocator = allocator,
        };
        
        // Set default unlocks for regions
        try data.unlocked_regions.put("temperate", true);
        
        return data;
    }
    
    /// Clean up resources
    pub fn deinit(self: *PlayerData) void {
        self.completed_missions.deinit();
        self.discovered_regions.deinit();
        self.unlocked_scenarios.deinit();
        self.unlocked_regions.deinit();
        self.high_scores.deinit();
        self.unlocked_arcade_features.deinit();
        self.achievements.deinit();
    }
    
    /// Save player data to a file
    pub fn saveToFile(self: *PlayerData, path: []const u8) !void {
        var file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        
        var writer = file.writer();
        
        // Character data
        try writer.print("character_level={d}\n", .{self.character_level});
        try writer.print("management_skill={d:.1}\n", .{self.management_skill});
        try writer.print("engineering_skill={d:.1}\n", .{self.engineering_skill});
        try writer.print("negotiation_skill={d:.1}\n", .{self.negotiation_skill});
        try writer.print("exploration_skill={d:.1}\n", .{self.exploration_skill});
        try writer.print("environmental_skill={d:.1}\n", .{self.environmental_skill});
        
        // Tycoon data
        try writer.print("company_reputation={d:.1}\n", .{self.company_reputation});
        try writer.print("total_earnings={d:.2}\n", .{self.total_earnings});
        try writer.print("largest_oilfield_size={d:.2}\n", .{self.largest_oilfield_size});
        try writer.print("company_value={d:.2}\n", .{self.company_value});
        
        // Campaign data - completed missions
        try writer.print("completed_missions=", .{});
        var mission_iter = self.completed_missions.iterator();
        var first_mission = true;
        while (mission_iter.next()) |entry| {
            if (entry.value_ptr.*) {
                if (!first_mission) {
                    try writer.print(",", .{});
                }
                try writer.print("{s}", .{entry.key_ptr.*});
                first_mission = false;
            }
        }
        try writer.print("\n", .{});
        
        // Campaign data - discovered regions
        try writer.print("discovered_regions=", .{});
        var region_iter = self.discovered_regions.iterator();
        var first_region = true;
        while (region_iter.next()) |entry| {
            if (entry.value_ptr.*) {
                if (!first_region) {
                    try writer.print(",", .{});
                }
                try writer.print("{s}", .{entry.key_ptr.*});
                first_region = false;
            }
        }
        try writer.print("\n", .{});
        
        // Sandbox unlocks - scenarios
        try writer.print("unlocked_scenarios=", .{});
        var scenario_iter = self.unlocked_scenarios.iterator();
        var first_scenario = true;
        while (scenario_iter.next()) |entry| {
            if (entry.value_ptr.*) {
                if (!first_scenario) {
                    try writer.print(",", .{});
                }
                try writer.print("{s}", .{entry.key_ptr.*});
                first_scenario = false;
            }
        }
        try writer.print("\n", .{});
        
        // Sandbox unlocks - regions
        try writer.print("unlocked_regions=", .{});
        var unlocked_region_iter = self.unlocked_regions.iterator();
        var first_unlocked_region = true;
        while (unlocked_region_iter.next()) |entry| {
            if (entry.value_ptr.*) {
                if (!first_unlocked_region) {
                    try writer.print(",", .{});
                }
                try writer.print("{s}", .{entry.key_ptr.*});
                first_unlocked_region = false;
            }
        }
        try writer.print("\n", .{});
        
        // Arcade data - high scores
        try writer.print("high_scores=", .{});
        var score_iter = self.high_scores.iterator();
        var first_score = true;
        while (score_iter.next()) |entry| {
            if (!first_score) {
                try writer.print(",", .{});
            }
            try writer.print("{s}:{d}", .{entry.key_ptr.*, entry.value_ptr.*});
            first_score = false;
        }
        try writer.print("\n", .{});
        
        // Arcade data - unlocked features
        try writer.print("unlocked_arcade_features=", .{});
        var feature_iter = self.unlocked_arcade_features.iterator();
        var first_feature = true;
        while (feature_iter.next()) |entry| {
            if (entry.value_ptr.*) {
                if (!first_feature) {
                    try writer.print(",", .{});
                }
                try writer.print("{s}", .{entry.key_ptr.*});
                first_feature = false;
            }
        }
        try writer.print("\n", .{});
        
        // Achievements
        try writer.print("achievements=", .{});
        var achievement_iter = self.achievements.iterator();
        var first_achievement = true;
        while (achievement_iter.next()) |entry| {
            if (entry.value_ptr.*) {
                if (!first_achievement) {
                    try writer.print(",", .{});
                }
                try writer.print("{s}", .{entry.key_ptr.*});
                first_achievement = false;
            }
        }
        try writer.print("\n", .{});
    }
    
    /// Load player data from a file
    pub fn loadFromFile(allocator: std.mem.Allocator, path: []const u8) !PlayerData {
        var data = try PlayerData.init(allocator);
        
        var file = std.fs.cwd().openFile(path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                return data; // Return default data if file doesn't exist
            }
            return err;
        };
        defer file.close();
        
        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        
        var buf: [1024]u8 = undefined;
        
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 0) continue;
            
            var parts = std.mem.splitScalar(u8, line, '=');
            const key = parts.next() orelse continue;
            const value = parts.next() orelse continue;
            
            if (std.mem.eql(u8, key, "character_level")) {
                data.character_level = try std.fmt.parseInt(u32, value, 10);
            } else if (std.mem.eql(u8, key, "management_skill")) {
                data.management_skill = try std.fmt.parseFloat(f32, value);
            } else if (std.mem.eql(u8, key, "engineering_skill")) {
                data.engineering_skill = try std.fmt.parseFloat(f32, value);
            } else if (std.mem.eql(u8, key, "negotiation_skill")) {
                data.negotiation_skill = try std.fmt.parseFloat(f32, value);
            } else if (std.mem.eql(u8, key, "exploration_skill")) {
                data.exploration_skill = try std.fmt.parseFloat(f32, value);
            } else if (std.mem.eql(u8, key, "environmental_skill")) {
                data.environmental_skill = try std.fmt.parseFloat(f32, value);
            } else if (std.mem.eql(u8, key, "company_reputation")) {
                data.company_reputation = try std.fmt.parseFloat(f32, value);
            } else if (std.mem.eql(u8, key, "total_earnings")) {
                data.total_earnings = try std.fmt.parseFloat(f64, value);
            } else if (std.mem.eql(u8, key, "largest_oilfield_size")) {
                data.largest_oilfield_size = try std.fmt.parseFloat(f64, value);
            } else if (std.mem.eql(u8, key, "company_value")) {
                data.company_value = try std.fmt.parseFloat(f64, value);
            } else if (std.mem.eql(u8, key, "completed_missions")) {
                var missions_iter = std.mem.splitScalar(u8, value, ',');
                while (missions_iter.next()) |mission| {
                    if (mission.len > 0) {
                        const mission_key = try allocator.dupe(u8, mission);
                        try data.completed_missions.put(mission_key, true);
                    }
                }
            } else if (std.mem.eql(u8, key, "discovered_regions")) {
                var regions_iter = std.mem.splitScalar(u8, value, ',');
                while (regions_iter.next()) |region| {
                    if (region.len > 0) {
                        const region_key = try allocator.dupe(u8, region);
                        try data.discovered_regions.put(region_key, true);
                    }
                }
            } else if (std.mem.eql(u8, key, "unlocked_scenarios")) {
                var scenarios_iter = std.mem.splitScalar(u8, value, ',');
                while (scenarios_iter.next()) |scenario| {
                    if (scenario.len > 0) {
                        const scenario_key = try allocator.dupe(u8, scenario);
                        try data.unlocked_scenarios.put(scenario_key, true);
                    }
                }
            } else if (std.mem.eql(u8, key, "unlocked_regions")) {
                var regions_iter = std.mem.splitScalar(u8, value, ',');
                while (regions_iter.next()) |region| {
                    if (region.len > 0) {
                        const region_key = try allocator.dupe(u8, region);
                        try data.unlocked_regions.put(region_key, true);
                    }
                }
            } else if (std.mem.eql(u8, key, "high_scores")) {
                var scores_iter = std.mem.splitScalar(u8, value, ',');
                while (scores_iter.next()) |score_entry| {
                    if (score_entry.len > 0) {
                        var score_parts = std.mem.splitScalar(u8, score_entry, ':');
                        const score_key = score_parts.next() orelse continue;
                        const score_value = score_parts.next() orelse continue;
                        
                        const duped_key = try allocator.dupe(u8, score_key);
                        const score = try std.fmt.parseInt(u64, score_value, 10);
                        
                        try data.high_scores.put(duped_key, score);
                    }
                }
            } else if (std.mem.eql(u8, key, "unlocked_arcade_features")) {
                var features_iter = std.mem.splitScalar(u8, value, ',');
                while (features_iter.next()) |feature| {
                    if (feature.len > 0) {
                        const feature_key = try allocator.dupe(u8, feature);
                        try data.unlocked_arcade_features.put(feature_key, true);
                    }
                }
            } else if (std.mem.eql(u8, key, "achievements")) {
                var achievements_iter = std.mem.splitScalar(u8, value, ',');
                while (achievements_iter.next()) |achievement| {
                    if (achievement.len > 0) {
                        const achievement_key = try allocator.dupe(u8, achievement);
                        try data.achievements.put(achievement_key, true);
                    }
                }
            }
        }
        
        return data;
    }
    
    /// Generate bonuses based on player progression
    pub fn generateBonuses(self: *const PlayerData) PlayerBonuses {
        return PlayerBonuses{
            .extraction_rate_bonus = self.engineering_skill * 0.05, // 0-50% bonus at max skill
            .discovery_chance_bonus = self.exploration_skill * 0.03, // 0-30% bonus at max skill
            .negotiation_price_bonus = self.negotiation_skill * 0.02, // 0-20% bonus at max skill
            .disaster_risk_reduction = self.environmental_skill * 0.05, // 0-50% reduction at max skill
            .management_efficiency_bonus = self.management_skill * 0.04, // 0-40% bonus at max skill
            .reputation_bonus = (self.company_reputation - 50.0) * 0.01, // -0.5 to +0.5 based on company rep
        };
    }
    
    /// Unlock a region for use in sandbox mode based on campaign progress
    pub fn unlockRegion(self: *PlayerData, region_name: []const u8) !void {
        const duped_key = try self.allocator.dupe(u8, region_name);
        try self.unlocked_regions.put(duped_key, true);
    }
    
    /// Check if a region is unlocked
    pub fn isRegionUnlocked(self: *const PlayerData, region_name: []const u8) bool {
        return self.unlocked_regions.get(region_name) orelse false;
    }
    
    /// Unlock a scenario for sandbox mode
    pub fn unlockScenario(self: *PlayerData, scenario_name: []const u8) !void {
        const duped_key = try self.allocator.dupe(u8, scenario_name);
        try self.unlocked_scenarios.put(duped_key, true);
    }
    
    /// Check if a scenario is unlocked
    pub fn isScenarioUnlocked(self: *const PlayerData, scenario_name: []const u8) bool {
        return self.unlocked_scenarios.get(scenario_name) orelse false;
    }
    
    /// Record completing a mission
    pub fn completeMission(self: *PlayerData, mission_name: []const u8) !void {
        const duped_key = try self.allocator.dupe(u8, mission_name);
        try self.completed_missions.put(duped_key, true);
    }
    
    /// Check if a mission is completed
    pub fn isMissionCompleted(self: *const PlayerData, mission_name: []const u8) bool {
        return self.completed_missions.get(mission_name) orelse false;
    }
    
    /// Record discovering a region in campaign mode
    pub fn discoverRegion(self: *PlayerData, region_name: []const u8) !void {
        const duped_key = try self.allocator.dupe(u8, region_name);
        try self.discovered_regions.put(duped_key, true);
        
        // Also unlock for sandbox mode
        try self.unlockRegion(region_name);
    }
    
    /// Check if a region has been discovered
    pub fn isRegionDiscovered(self: *const PlayerData, region_name: []const u8) bool {
        return self.discovered_regions.get(region_name) orelse false;
    }
    
    /// Update a high score if it's better than the current one
    pub fn updateHighScore(self: *PlayerData, level_name: []const u8, score: u64) !void {
        const current = self.high_scores.get(level_name) orelse 0;
        if (score > current) {
            const duped_key = try self.allocator.dupe(u8, level_name);
            try self.high_scores.put(duped_key, score);
        }
    }
    
    /// Get a high score for a level
    pub fn getHighScore(self: *const PlayerData, level_name: []const u8) u64 {
        return self.high_scores.get(level_name) orelse 0;
    }
    
    /// Unlock an arcade feature
    pub fn unlockArcadeFeature(self: *PlayerData, feature_name: []const u8) !void {
        const duped_key = try self.allocator.dupe(u8, feature_name);
        try self.unlocked_arcade_features.put(duped_key, true);
    }
    
    /// Check if an arcade feature is unlocked
    pub fn isArcadeFeatureUnlocked(self: *const PlayerData, feature_name: []const u8) bool {
        return self.unlocked_arcade_features.get(feature_name) orelse false;
    }
    
    /// Unlock an achievement
    pub fn unlockAchievement(self: *PlayerData, achievement_name: []const u8) !void {
        const duped_key = try self.allocator.dupe(u8, achievement_name);
        try self.achievements.put(duped_key, true);
    }
    
    /// Check if an achievement is unlocked
    pub fn isAchievementUnlocked(self: *const PlayerData, achievement_name: []const u8) bool {
        return self.achievements.get(achievement_name) orelse false;
    }
    
    /// Count total achievements
    pub fn getAchievementCount(self: *const PlayerData) usize {
        var count: usize = 0;
        var iter = self.achievements.iterator();
        while (iter.next()) |entry| {
            if (entry.value_ptr.*) {
                count += 1;
            }
        }
        return count;
    }
    
    /// Increase character skill
    pub fn increaseSkill(self: *PlayerData, skill_type: CharacterSkill, amount: f32) void {
        switch (skill_type) {
            .management => self.management_skill = std.math.min(10.0, self.management_skill + amount),
            .engineering => self.engineering_skill = std.math.min(10.0, self.engineering_skill + amount),
            .negotiation => self.negotiation_skill = std.math.min(10.0, self.negotiation_skill + amount),
            .exploration => self.exploration_skill = std.math.min(10.0, self.exploration_skill + amount),
            .environmental => self.environmental_skill = std.math.min(10.0, self.environmental_skill + amount),
        }
    }
};

/// Character skill types
pub const CharacterSkill = enum {
    management,
    engineering,
    negotiation,
    exploration,
    environmental,
};

/// Gameplay bonuses based on player progression
pub const PlayerBonuses = struct {
    extraction_rate_bonus: f32, // Percentage increase to extraction rate
    discovery_chance_bonus: f32, // Percentage increase to chance of discovering oil
    negotiation_price_bonus: f32, // Percentage increase to oil price when selling
    disaster_risk_reduction: f32, // Percentage decrease in disaster risk
    management_efficiency_bonus: f32, // Percentage decrease in operational costs
    reputation_bonus: f32, // Bonus or penalty based on company reputation
    
    /// Apply bonuses to extraction rate
    pub fn applyToExtractionRate(self: PlayerBonuses, base_rate: f32) f32 {
        return base_rate * (1.0 + self.extraction_rate_bonus);
    }
    
    /// Apply bonuses to discovery chance
    pub fn applyToDiscoveryChance(self: PlayerBonuses, base_chance: f32) f32 {
        return base_chance * (1.0 + self.discovery_chance_bonus);
    }
    
    /// Apply bonuses to oil price
    pub fn applyToOilPrice(self: PlayerBonuses, base_price: f32) f32 {
        return base_price * (1.0 + self.negotiation_price_bonus + self.reputation_bonus);
    }
    
    /// Apply bonuses to disaster risk
    pub fn applyToDisasterRisk(self: PlayerBonuses, base_risk: f32) f32 {
        return base_risk * (1.0 - self.disaster_risk_reduction);
    }
    
    /// Apply bonuses to operational costs
    pub fn applyToOperationalCosts(self: PlayerBonuses, base_cost: f32) f32 {
        return base_cost * (1.0 - self.management_efficiency_bonus);
    }
};

/// Global instance of player data
var global_player_data: ?PlayerData = null;

/// Initialize the global player data
pub fn initGlobalPlayerData(allocator: std.mem.Allocator) !void {
    if (global_player_data != null) {
        return error.AlreadyInitialized;
    }
    
    // Try to load from file, create new data if file doesn't exist
    global_player_data = PlayerData.loadFromFile(allocator, "player_data.txt") catch |err| {
        if (err == error.FileNotFound) {
            // If file doesn't exist, create new player data
            global_player_data = try PlayerData.init(allocator);
            return;
        }
        // For other errors, propagate them up
        return err;
    };
}

/// Get the global player data
pub fn getGlobalPlayerData() ?*PlayerData {
    if (global_player_data) |*data| {
        return data;
    }
    return null;
}

/// Save the global player data
pub fn saveGlobalPlayerData() !void {
    if (global_player_data) |*data| {
        try data.saveToFile("player_data.txt");
    } else {
        return error.NotInitialized;
    }
}

/// Close and clean up global player data
pub fn closeGlobalPlayerData() void {
    if (global_player_data) |*data| {
        data.deinit();
        global_player_data = null;
    }
} 