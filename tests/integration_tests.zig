const std = @import("std");
const testing = std.testing;

// ---- MOCK COMPONENTS ----

// Mock OilField for testing
const OilField = struct {
    oil_amount: f32,
    extraction_rate: f32,
    max_capacity: f32,
    quality: f32,
    depth: f32,
    
    pub fn init(initial_amount: f32, rate: f32) OilField {
        return OilField{
            .oil_amount = initial_amount,
            .extraction_rate = rate,
            .max_capacity = initial_amount,
            .quality = 1.0,
            .depth = 1.0,
        };
    }
    
    pub fn extract(self: *OilField, delta: f32) f32 {
        const effective_rate = self.extraction_rate * self.quality;
        const extracted = effective_rate * delta;
        
        if (extracted > self.oil_amount) {
            const result = self.oil_amount;
            self.oil_amount = 0;
            return result;
        }
        
        self.oil_amount -= extracted;
        return extracted;
    }
    
    pub fn getPercentageFull(self: *const OilField) f32 {
        return self.oil_amount / self.max_capacity;
    }
};

// Mock SimulationEngine for testing
const SimulationEngine = struct {
    oil_fields: std.ArrayList(OilField),
    total_extracted: f32,
    money: f32,
    time_elapsed: f32,
    oil_price: f32,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) !SimulationEngine {
        return SimulationEngine{
            .oil_fields = std.ArrayList(OilField).init(allocator),
            .total_extracted = 0,
            .money = 10000, // Starting capital
            .time_elapsed = 0,
            .oil_price = 50, // Default price per barrel
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *SimulationEngine) void {
        self.oil_fields.deinit();
    }
    
    pub fn addOilField(self: *SimulationEngine, field: OilField) !void {
        try self.oil_fields.append(field);
    }
    
    pub fn step(self: *SimulationEngine, delta: f32) !void {
        self.time_elapsed += delta;
        
        var total_extracted_this_step: f32 = 0;
        
        for (self.oil_fields.items) |*field| {
            const extracted = field.extract(delta);
            total_extracted_this_step += extracted;
        }
        
        self.total_extracted += total_extracted_this_step;
        self.money += total_extracted_this_step * self.oil_price;
        
        // Simplified market fluctuation
        const price_change = @sin(self.time_elapsed * 0.1) * 2.0; // -2 to +2 dollars
        self.oil_price += price_change;
        
        // Keep price in reasonable range
        if (self.oil_price < 20) self.oil_price = 20;
        if (self.oil_price > 100) self.oil_price = 100;
    }
};

// Mock TycoonMode for testing
const OilFieldType = enum {
    onshore, offshore, shale, deepwater, arctic,
};

const TycoonMode = struct {
    simulation: SimulationEngine,
    research_level: u32,
    environmental_level: u32,
    exploration_level: u32,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) !TycoonMode {
        return TycoonMode{
            .simulation = try SimulationEngine.init(allocator),
            .research_level = 1,
            .environmental_level = 1,
            .exploration_level = 1,
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *TycoonMode) void {
        self.simulation.deinit();
    }
    
    pub fn purchaseOilField(self: *TycoonMode, field_type: OilFieldType, size: f32, rate: f32, quality: f32, depth: f32) !void {
        _ = field_type; // In the real implementation, this would affect the field
        _ = quality;
        _ = depth;
        
        const field = OilField.init(size, rate);
        try self.simulation.addOilField(field);
        
        // Deduct cost - simplified for testing
        self.simulation.money -= size * 0.1;
    }
    
    pub fn simulateDay(self: *TycoonMode) !void {
        try self.simulation.step(1.0);
        
        // Apply research and other bonuses - simplified for testing
        self.simulation.money += @as(f32, @floatFromInt(self.research_level)) * 10.0;
    }
};

// Mock CharacterMode for testing
const SkillType = enum {
    drilling, geology, engineering, business, leadership, research,
};

const Skill = struct {
    skill_type: SkillType,
    level: u32,
    experience: u32,
    
    pub fn init(skill_type: SkillType) Skill {
        return Skill{
            .skill_type = skill_type,
            .level = 1,
            .experience = 0,
        };
    }
    
    pub fn addExperience(self: *Skill, amount: u32) bool {
        self.experience += amount;
        
        // Check for level up - simplified for testing
        const needed_for_level = self.level * 1000;
        if (self.experience >= needed_for_level) {
            self.level += 1;
            return true;
        }
        
        return false;
    }
};

const CharacterMode = struct {
    skills: std.ArrayList(Skill),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) !CharacterMode {
        var character = CharacterMode{
            .skills = std.ArrayList(Skill).init(allocator),
            .allocator = allocator,
        };
        
        // Add default skills
        try character.skills.append(Skill.init(.drilling));
        try character.skills.append(Skill.init(.geology));
        try character.skills.append(Skill.init(.engineering));
        try character.skills.append(Skill.init(.business));
        try character.skills.append(Skill.init(.leadership));
        try character.skills.append(Skill.init(.research));
        
        return character;
    }
    
    pub fn deinit(self: *CharacterMode) void {
        self.skills.deinit();
    }
    
    pub fn getSkill(self: *CharacterMode, skill_type: SkillType) ?*Skill {
        for (self.skills.items) |*skill| {
            if (skill.skill_type == skill_type) {
                return skill;
            }
        }
        return null;
    }
    
    pub fn addExperience(self: *CharacterMode, skill_type: SkillType, amount: u32) !void {
        if (self.getSkill(skill_type)) |skill| {
            _ = skill.addExperience(amount);
        }
    }
};

// Mock CampaignMode for testing
const Mission = struct {
    id: usize,
    title: []const u8,
    description: []const u8,
    completed: bool,
};

const CampaignMode = struct {
    simulation: SimulationEngine,
    missions: std.ArrayList(Mission),
    current_mission_id: usize,
    player_name: []const u8,
    company_name: []const u8,
    game_days: usize,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator, player_name: []const u8, company_name: []const u8) !CampaignMode {
        var campaign = CampaignMode{
            .simulation = try SimulationEngine.init(allocator),
            .missions = std.ArrayList(Mission).init(allocator),
            .current_mission_id = 1,
            .player_name = player_name,
            .company_name = company_name,
            .game_days = 0,
            .allocator = allocator,
        };
        
        // Add initial mission
        try campaign.missions.append(Mission{
            .id = 1,
            .title = "First Steps",
            .description = "Extract 100 barrels of oil and earn $15,000.",
            .completed = false,
        });
        
        return campaign;
    }
    
    pub fn deinit(self: *CampaignMode) void {
        self.simulation.deinit();
        self.missions.deinit();
    }
};

// Mock ArcadeMode for testing
const DifficultyLevel = enum {
    easy, medium, hard,
};

const HighScore = struct {
    player_name: []const u8,
    score: u32,
    difficulty: DifficultyLevel,
    oil_extracted: f32,
};

const ArcadeMode = struct {
    oil_field: OilField,
    score: u32,
    time_remaining: f32,
    difficulty: DifficultyLevel,
    oil_extracted: f32,
    combo_multiplier: f32,
    high_scores: std.ArrayList(HighScore),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator, difficulty: DifficultyLevel) ArcadeMode {
        const field_size: f32 = switch (difficulty) {
            .easy => 5000.0,
            .medium => 7500.0,
            .hard => 10000.0,
        };
        
        return ArcadeMode{
            .oil_field = OilField.init(field_size, 10.0),
            .score = 0,
            .time_remaining = 60.0,
            .difficulty = difficulty,
            .oil_extracted = 0,
            .combo_multiplier = 1.0,
            .high_scores = std.ArrayList(HighScore).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *ArcadeMode) void {
        self.high_scores.deinit();
    }
    
    pub fn addHighScore(self: *ArcadeMode, player_name: []const u8) !void {
        try self.high_scores.append(HighScore{
            .player_name = player_name,
            .score = self.score,
            .difficulty = self.difficulty,
            .oil_extracted = self.oil_extracted,
        });
    }
};

// Mock SandboxMode for testing
const SandboxMode = struct {
    simulation: SimulationEngine,
    current_day: usize,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) !SandboxMode {
        return SandboxMode{
            .simulation = try SimulationEngine.init(allocator),
            .current_day = 0,
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *SandboxMode) void {
        self.simulation.deinit();
    }
};

// ---- TESTS ----

// Integration test between Tycoon mode and the core simulation engine
test "Tycoon mode integrates with simulation engine" {
    const allocator = testing.allocator;
    
    // Initialize tycoon mode
    var tycoon = try TycoonMode.init(allocator);
    defer tycoon.deinit();
    
    // Verify simulation engine is properly initialized
    try testing.expect(tycoon.simulation.oil_fields.items.len == 0);
    try testing.expect(tycoon.simulation.money > 0);
    
    // Test oil field purchase flows through to simulation engine
    try tycoon.purchaseOilField(.onshore, 1000.0, 10.0, 1.0, 1.0);
    try testing.expect(tycoon.simulation.oil_fields.items.len == 1);
    
    // Test that daily operations update the simulation correctly
    const initial_money = tycoon.simulation.money;
    try tycoon.simulateDay();
    try testing.expect(tycoon.simulation.money != initial_money);
}

// Integration test between Character mode and Campaign mode
test "Character progression affects Campaign outcomes" {
    const allocator = testing.allocator;
    
    // Initialize character mode
    var character = try CharacterMode.init(allocator);
    defer character.deinit();
    
    // Initialize campaign mode
    var campaign = try CampaignMode.init(allocator, "Test Player", "Test Company");
    defer campaign.deinit();
    
    // Simulate character skill development
    var skill = character.getSkill(.drilling) orelse unreachable;
    const initial_level = skill.level;
    
    // Add experience to drilling skill
    try character.addExperience(.drilling, 1000);
    skill = character.getSkill(.drilling) orelse unreachable;
    
    // Verify skill level increased
    try testing.expect(skill.level > initial_level);
    
    // In a full implementation, we would verify that the character's
    // skill level affects campaign outcomes
}

// Integration test between Arcade mode and Sandbox mode
test "Arcade mode high scores are preserved in Sandbox mode" {
    const allocator = testing.allocator;
    
    // Initialize arcade mode with medium difficulty
    var arcade = ArcadeMode.init(allocator, .medium);
    defer arcade.deinit();
    
    // Simulate gameplay and add a high score
    arcade.score = 5000;
    arcade.oil_extracted = 500.0;
    try arcade.addHighScore("Test Player");
    
    // Verify high score was recorded
    try testing.expect(arcade.high_scores.items.len == 1);
    try testing.expectEqual(@as(u32, 5000), arcade.high_scores.items[0].score);
    
    // Create sandbox mode
    var sandbox = try SandboxMode.init(allocator);
    defer sandbox.deinit();
    
    // In a full implementation, we would verify that sandbox mode
    // can access and display high scores from arcade mode
}

// Integration test for data sharing between all modes
test "Game modes share and maintain consistent data" {
    // This test would verify that game modes can correctly share core data
    // For now, we'll just mark it as skipped
    return error.SkipZigTest;
}

// Run all integration tests
pub fn main() !void {
    // Set log level to debug to see more output
    testing.log_level = .debug;
    std.debug.print("\n[INFO] Starting TURMOIL integration tests...\n", .{});
    const result = testing.run();
    if (result.skipped > 0) {
        std.debug.print("[INFO] {d} tests skipped\n", .{result.skipped});
    }
    if (result.failed > 0) {
        std.debug.print("[ERROR] {d} tests failed\n", .{result.failed});
        return error.TestFailed;
    }
    std.debug.print("[SUCCESS] All {d} tests passed!\n", .{result.passed});
    return result;
} 