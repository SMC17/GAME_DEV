const std = @import("std");

/// Skill type defining areas of expertise
pub const SkillType = enum {
    drilling,    // Affects oil extraction efficiency
    geology,     // Affects oil field discovery and quality assessment
    engineering, // Affects equipment efficiency and reliability
    business,    // Affects financial operations and negotiation
    leadership,  // Affects staff management and morale
    research,    // Affects technology development
    
    /// Get the description for this skill
    pub fn getDescription(self: SkillType) []const u8 {
        return switch (self) {
            .drilling => "Knowledge of drilling techniques and field operations",
            .geology => "Understanding of geological formations and oil deposit identification",
            .engineering => "Technical expertise in oil extraction equipment and processes",
            .business => "Financial acumen and market awareness",
            .leadership => "Management of teams and crisis handling",
            .research => "Scientific knowledge and innovation capabilities",
        };
    }
    
    /// Get the effect description for this skill
    pub fn getEffectDescription(self: SkillType) []const u8 {
        return switch (self) {
            .drilling => "Increases extraction rate by 5% per level",
            .geology => "Improves oil field assessment accuracy by 10% per level",
            .engineering => "Reduces equipment failure by 5% per level",
            .business => "Improves sale prices by 2% per level",
            .leadership => "Increases staff productivity by 3% per level",
            .research => "Speeds up research by 5% per level",
        };
    }
};

/// Trait representing character personality traits
pub const CharacterTrait = enum {
    ambitious,    // Faster skill progression
    cautious,     // Reduced risk of accidents
    charismatic,  // Better prices in negotiations
    innovative,   // Better research outcomes
    methodical,   // More thorough in operations
    risk_taker,   // Higher chance of discovering rich fields
    
    /// Get the description for this trait
    pub fn getDescription(self: CharacterTrait) []const u8 {
        return switch (self) {
            .ambitious => "Always striving for more, learns quickly but can be impatient",
            .cautious => "Careful and measured approach to challenges",
            .charismatic => "Excellent people skills, persuasive in negotiations",
            .innovative => "Creative thinker who finds unconventional solutions",
            .methodical => "Thorough and organized, leaves nothing to chance",
            .risk_taker => "Bold decision maker who thrives on uncertainty",
        };
    }
    
    /// Get the effect of this trait
    pub fn getEffect(self: CharacterTrait) []const u8 {
        return switch (self) {
            .ambitious => "25% faster skill progression, -5% to careful operations",
            .cautious => "50% reduced accident chance, 10% slower operations",
            .charismatic => "15% better prices in negotiations, 5% bonus to reputation",
            .innovative => "20% improved research outcomes, 5% higher research costs",
            .methodical => "10% more thorough oil field assessment, 5% slower operations",
            .risk_taker => "25% higher chance of rich fields, 20% higher accident risk",
        };
    }
};

/// Background representing character's professional history
pub const CharacterBackground = enum {
    field_worker,   // Started as a roughneck on oil rigs
    geologist,      // Academic background in geology
    engineer,       // Technical education and experience
    business_grad,  // Business school graduate
    entrepreneur,   // Self-made business person
    military,       // Former military officer
    
    /// Get the description for this background
    pub fn getDescription(self: CharacterBackground) []const u8 {
        return switch (self) {
            .field_worker => "Started as a roughneck on oil rigs, knows the industry from the ground up",
            .geologist => "Academic with expertise in finding and assessing oil deposits",
            .engineer => "Technical expert in oil extraction technology and equipment",
            .business_grad => "Business school education with focus on energy markets",
            .entrepreneur => "Self-made business person with experience in startups",
            .military => "Former military officer with leadership and logistics experience",
        };
    }
    
    /// Get the starting skill bonuses for this background
    pub fn getStartingSkills(self: CharacterBackground) [6]u8 {
        return switch (self) {
            .field_worker => [_]u8{ 3, 1, 2, 0, 1, 0 }, // drilling, geology, engineering, business, leadership, research
            .geologist => [_]u8{ 1, 3, 1, 0, 0, 2 },
            .engineer => [_]u8{ 1, 1, 3, 0, 0, 2 },
            .business_grad => [_]u8{ 0, 0, 0, 3, 2, 1 },
            .entrepreneur => [_]u8{ 0, 0, 1, 3, 2, 1 },
            .military => [_]u8{ 1, 0, 1, 1, 3, 0 },
        };
    }
};

/// Quest representing a character-specific mission or objective
pub const CharacterQuest = struct {
    id: usize,
    title: []const u8,
    description: []const u8,
    objective_type: QuestObjectiveType,
    target_value: f32,
    current_value: f32,
    reward_xp: u32,
    reward_money: f32,
    completed: bool,
    
    /// Check if the quest is complete
    pub fn isComplete(self: *const CharacterQuest) bool {
        return self.completed or self.current_value >= self.target_value;
    }
    
    /// Update quest progress
    pub fn updateProgress(self: *CharacterQuest, value: f32) void {
        self.current_value += value;
        if (self.current_value >= self.target_value) {
            self.completed = true;
        }
    }
    
    /// Get progress percentage
    pub fn getProgressPercentage(self: *const CharacterQuest) f32 {
        return @min(1.0, self.current_value / self.target_value);
    }
};

/// Quest objective types
pub const QuestObjectiveType = enum {
    extract_oil,         // Extract a certain amount of oil
    earn_money,          // Earn a certain amount of money
    research_projects,   // Complete a number of research projects
    upgrade_skills,      // Upgrade skills to a certain level
    manage_crises,       // Successfully manage a number of crises
    acquire_oil_fields,  // Acquire a number of oil fields
};

/// Skill representing a character's ability in a specific area
pub const Skill = struct {
    skill_type: SkillType,
    level: u8,
    experience_points: u32,
    
    /// Calculate the points needed for the next level
    pub fn pointsToNextLevel(self: *const Skill) u32 {
        return (self.level + 1) * 100;
    }
    
    /// Add experience points and level up if enough
    pub fn addExperience(self: *Skill, xp: u32) bool {
        self.experience_points += xp;
        
        if (self.experience_points >= self.pointsToNextLevel()) {
            self.level += 1;
            return true; // Level up occurred
        }
        
        return false;
    }
    
    /// Get progress percentage to next level
    pub fn getLevelProgress(self: *const Skill) f32 {
        const points_needed = self.pointsToNextLevel();
        return @as(f32, @floatFromInt(self.experience_points)) / @as(f32, @floatFromInt(points_needed));
    }
};

/// Character representing the player's persona in the game
pub const Character = struct {
    name: []const u8,
    background: CharacterBackground,
    traits: std.ArrayList(CharacterTrait),
    skills: [6]Skill, // One for each SkillType
    level: u32,
    total_xp: u32,
    money: f32,
    reputation: f32, // 0.0 to 1.0
    active_quests: std.ArrayList(CharacterQuest),
    completed_quests: std.ArrayList(CharacterQuest),
    allocator: std.mem.Allocator,
    
    /// Initialize a new character
    pub fn init(allocator: std.mem.Allocator, name: []const u8, background: CharacterBackground) !Character {
        const traits = std.ArrayList(CharacterTrait).init(allocator);
        const active_quests = std.ArrayList(CharacterQuest).init(allocator);
        const completed_quests = std.ArrayList(CharacterQuest).init(allocator);
        
        // Initialize skills based on background
        const starting_skill_levels = background.getStartingSkills();
        var skills: [6]Skill = undefined;
        
        inline for (std.meta.tags(SkillType), 0..) |skill_type, i| {
            skills[i] = Skill{
                .skill_type = skill_type,
                .level = starting_skill_levels[i],
                .experience_points = 0,
            };
        }
        
        return Character{
            .name = name,
            .background = background,
            .traits = traits,
            .skills = skills,
            .level = 1,
            .total_xp = 0,
            .money = 5000.0, // Starting money
            .reputation = 0.5, // Neutral reputation
            .active_quests = active_quests,
            .completed_quests = completed_quests,
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *Character) void {
        self.traits.deinit();
        self.active_quests.deinit();
        self.completed_quests.deinit();
    }
    
    /// Add a trait to the character
    pub fn addTrait(self: *Character, trait: CharacterTrait) !void {
        // Check if character already has this trait
        for (self.traits.items) |existing_trait| {
            if (existing_trait == trait) {
                return; // Already has this trait
            }
        }
        
        try self.traits.append(trait);
    }
    
    /// Get the skill level for a specific skill type
    pub fn getSkillLevel(self: *const Character, skill_type: SkillType) u8 {
        const index = @intFromEnum(skill_type);
        return self.skills[index].level;
    }
    
    /// Add experience to a specific skill
    pub fn addSkillExperience(self: *Character, skill_type: SkillType, xp: u32) bool {
        const index = @intFromEnum(skill_type);
        
        // Apply trait modifiers
        var modified_xp = xp;
        for (self.traits.items) |trait| {
            if (trait == .ambitious) {
                modified_xp = @as(u32, @intFromFloat(@as(f32, @floatFromInt(modified_xp)) * 1.25));
            }
        }
        
        return self.skills[index].addExperience(modified_xp);
    }
    
    /// Add a new quest
    pub fn addQuest(self: *Character, quest: CharacterQuest) !void {
        try self.active_quests.append(quest);
    }
    
    /// Update quest progress
    pub fn updateQuestProgress(self: *Character, objective_type: QuestObjectiveType, progress: f32) !void {
        var completed_quest_indices = std.ArrayList(usize).init(self.allocator);
        defer completed_quest_indices.deinit();
        
        // Update all matching quests
        for (self.active_quests.items, 0..) |*quest, i| {
            if (quest.objective_type == objective_type) {
                quest.updateProgress(progress);
                
                if (quest.isComplete()) {
                    // Add XP and money reward
                    self.total_xp += quest.reward_xp;
                    self.money += quest.reward_money;
                    
                    // Check for level up
                    const new_level = 1 + (self.total_xp / 1000); // Simple level calculation
                    if (new_level > self.level) {
                        self.level = new_level;
                    }
                    
                    // Mark for completion
                    try completed_quest_indices.append(i);
                }
            }
        }
        
        // Move completed quests from active to completed
        // Process in reverse order to maintain correct indices
        var i: usize = completed_quest_indices.items.len;
        while (i > 0) {
            i -= 1;
            const index = completed_quest_indices.items[i];
            const quest = self.active_quests.orderedRemove(index);
            try self.completed_quests.append(quest);
        }
    }
    
    /// Calculate the modifier for a specific skill type
    pub fn getSkillModifier(self: *const Character, skill_type: SkillType) f32 {
        const level = self.getSkillLevel(skill_type);
        
        return switch (skill_type) {
            .drilling => 1.0 + (0.05 * @as(f32, @floatFromInt(level))),
            .geology => 1.0 + (0.10 * @as(f32, @floatFromInt(level))),
            .engineering => 1.0 - (0.05 * @as(f32, @floatFromInt(level))), // Reduces failure rate
            .business => 1.0 + (0.02 * @as(f32, @floatFromInt(level))),
            .leadership => 1.0 + (0.03 * @as(f32, @floatFromInt(level))),
            .research => 1.0 + (0.05 * @as(f32, @floatFromInt(level))),
        };
    }
    
    /// Calculate the trait modifier for a specific effect
    pub fn getTraitModifier(self: *const Character, effect_type: TraitEffectType) f32 {
        var modifier: f32 = 1.0;
        
        for (self.traits.items) |trait| {
            modifier *= switch (effect_type) {
                .accident_risk => switch (trait) {
                    .cautious => 0.5,
                    .risk_taker => 1.2,
                    else => 1.0,
                },
                .operation_speed => switch (trait) {
                    .cautious => 0.9,
                    .methodical => 0.95,
                    else => 1.0,
                },
                .negotiation => switch (trait) {
                    .charismatic => 1.15,
                    else => 1.0,
                },
                .research_quality => switch (trait) {
                    .innovative => 1.2,
                    else => 1.0,
                },
                .research_cost => switch (trait) {
                    .innovative => 1.05,
                    else => 1.0,
                },
                .field_assessment => switch (trait) {
                    .methodical => 1.1,
                    else => 1.0,
                },
                .rich_field_chance => switch (trait) {
                    .risk_taker => 1.25,
                    else => 1.0,
                },
                .reputation_gain => switch (trait) {
                    .charismatic => 1.05,
                    else => 1.0,
                },
            };
        }
        
        return modifier;
    }
};

/// Types of effects that traits can modify
pub const TraitEffectType = enum {
    accident_risk,
    operation_speed,
    negotiation,
    research_quality,
    research_cost,
    field_assessment,
    rich_field_chance,
    reputation_gain,
};

/// Structure representing the character mode
pub const CharacterMode = struct {
    character: Character,
    current_day: u32,
    quest_manager: QuestManager,
    allocator: std.mem.Allocator,
    
    /// Initialize a new character mode
    pub fn init(allocator: std.mem.Allocator, character_name: []const u8, background: CharacterBackground) !CharacterMode {
        const character = try Character.init(allocator, character_name, background);
        const quest_manager = QuestManager.init(allocator);
        
        return CharacterMode{
            .character = character,
            .current_day = 1,
            .quest_manager = quest_manager,
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *CharacterMode) void {
        self.character.deinit();
        self.quest_manager.deinit();
    }
    
    /// Advance the game by one day
    pub fn advanceDay(self: *CharacterMode) !void {
        self.current_day += 1;
        
        // Check for new quests
        if (self.current_day % 5 == 0) { // New quest every 5 days
            if (self.character.active_quests.items.len < 3) { // Limit active quests
                if (try self.quest_manager.generateQuest(self.character.level)) |quest| {
                    try self.character.addQuest(quest);
                }
            }
        }
        
        // Random skill experience (from daily activities)
        const skill_index = @mod(self.current_day, 6);
        const skill_type = @as(SkillType, @enumFromInt(skill_index));
        _ = self.character.addSkillExperience(skill_type, 10);
        
        // Daily income based on business skill
        const business_modifier = self.character.getSkillModifier(.business);
        const daily_income = 100.0 * business_modifier;
        self.character.money += daily_income;
        
        // Update quest progress for money earned
        try self.character.updateQuestProgress(.earn_money, daily_income);
    }
};

/// Manager for generating and handling quests
pub const QuestManager = struct {
    next_quest_id: usize,
    allocator: std.mem.Allocator,
    
    /// Initialize a new quest manager
    pub fn init(allocator: std.mem.Allocator) QuestManager {
        return QuestManager{
            .next_quest_id = 1,
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *QuestManager) void {
        // Nothing to clean up currently
        _ = self;
    }
    
    /// Generate a new quest based on character level
    pub fn generateQuest(self: *QuestManager, character_level: u32) !?CharacterQuest {
        const quest_type_index = @mod(self.next_quest_id, 6);
        const quest_type = @as(QuestObjectiveType, @enumFromInt(quest_type_index));
        
        const level_multiplier = @as(f32, @floatFromInt(character_level));
        
        var title_buf: [100]u8 = undefined;
        var desc_buf: [200]u8 = undefined;
        var title: []const u8 = "";
        var description: []const u8 = "";
        var target_value: f32 = 0.0;
        var reward_xp: u32 = 0;
        var reward_money: f32 = 0.0;
        
        switch (quest_type) {
            .extract_oil => {
                const target = 1000.0 * level_multiplier;
                const xp = 100 * character_level;
                const money = 500.0 * level_multiplier;
                
                title = try std.fmt.bufPrint(&title_buf, "Extract {d:.0} Barrels", .{target});
                description = try std.fmt.bufPrint(&desc_buf, "Extract {d:.0} barrels of oil to fulfill a special contract.", .{target});
                target_value = target;
                reward_xp = xp;
                reward_money = money;
            },
            .earn_money => {
                const target = 5000.0 * level_multiplier;
                const xp = 120 * character_level;
                const money = 1000.0 * level_multiplier;
                
                title = try std.fmt.bufPrint(&title_buf, "Earn ${d:.0}", .{target});
                description = try std.fmt.bufPrint(&desc_buf, "Earn ${d:.0} to prove your business acumen.", .{target});
                target_value = target;
                reward_xp = xp;
                reward_money = money;
            },
            .research_projects => {
                const target = 1.0 + @divFloor(level_multiplier, 2.0);
                const xp = 150 * character_level;
                const money = 2000.0 * level_multiplier;
                
                title = try std.fmt.bufPrint(&title_buf, "Complete {d:.0} Research Projects", .{target});
                description = try std.fmt.bufPrint(&desc_buf, "Complete {d:.0} research projects to advance the industry.", .{target});
                target_value = target;
                reward_xp = xp;
                reward_money = money;
            },
            .upgrade_skills => {
                const target = 2.0 + @divFloor(level_multiplier, 3.0);
                const xp = 200 * character_level;
                const money = 1500.0 * level_multiplier;
                
                title = try std.fmt.bufPrint(&title_buf, "Upgrade Skills {d:.0} Times", .{target});
                description = try std.fmt.bufPrint(&desc_buf, "Improve your skills {d:.0} times to become more proficient.", .{target});
                target_value = target;
                reward_xp = xp;
                reward_money = money;
            },
            .manage_crises => {
                const target = 1.0 + @divFloor(level_multiplier, 4.0);
                const xp = 180 * character_level;
                const money = 2500.0 * level_multiplier;
                
                title = try std.fmt.bufPrint(&title_buf, "Manage {d:.0} Crises", .{target});
                description = try std.fmt.bufPrint(&desc_buf, "Successfully handle {d:.0} crises to prove your leadership.", .{target});
                target_value = target;
                reward_xp = xp;
                reward_money = money;
            },
            .acquire_oil_fields => {
                const target = 1.0 + @divFloor(level_multiplier, 3.0);
                const xp = 130 * character_level;
                const money = 3000.0 * level_multiplier;
                
                title = try std.fmt.bufPrint(&title_buf, "Acquire {d:.0} Oil Fields", .{target});
                description = try std.fmt.bufPrint(&desc_buf, "Expand your operations by acquiring {d:.0} new oil fields.", .{target});
                target_value = target;
                reward_xp = xp;
                reward_money = money;
            },
        }
        
        // Allocate and copy the strings for the quest
        const quest_title = try self.allocator.dupe(u8, title);
        const quest_description = try self.allocator.dupe(u8, description);
        
        const quest = CharacterQuest{
            .id = self.next_quest_id,
            .title = quest_title,
            .description = quest_description,
            .objective_type = quest_type,
            .target_value = target_value,
            .current_value = 0.0,
            .reward_xp = reward_xp,
            .reward_money = reward_money,
            .completed = false,
        };
        
        self.next_quest_id += 1;
        
        return quest;
    }
}; 