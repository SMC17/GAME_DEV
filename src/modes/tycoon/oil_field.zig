const std = @import("std");
const base_oil_field = @import("../../engine/oil_field.zig");

/// Extending the base OilField with tycoon-specific functionality
pub const OilField = base_oil_field.OilField;

/// Oil field type affecting value and extraction characteristics
pub const OilFieldType = enum {
    onshore,   // Standard, easier to access
    offshore,  // More expensive, harder to access, higher capacity
    shale,     // Requires special equipment, moderate yield
    deepwater, // Very expensive, difficult to access, high capacity
    arctic,    // Extreme conditions, high costs, potentially high yield
    
    /// Get the cost multiplier for this field type
    pub fn getCostMultiplier(self: OilFieldType) f32 {
        return switch (self) {
            .onshore => 1.0,
            .offshore => 1.5,
            .shale => 1.3,
            .deepwater => 2.0,
            .arctic => 2.5,
        };
    }
    
    /// Get the risk factor for this field type (affects extraction reliability)
    pub fn getRiskFactor(self: OilFieldType) f32 {
        return switch (self) {
            .onshore => 0.05,  // 5% risk of issues
            .offshore => 0.10, // 10% risk
            .shale => 0.15,    // 15% risk
            .deepwater => 0.20, // 20% risk
            .arctic => 0.25,   // 25% risk
        };
    }
    
    /// Get the operational cost multiplier
    pub fn getOperationalCostMultiplier(self: OilFieldType) f32 {
        return switch (self) {
            .onshore => 1.0,
            .offshore => 1.6,
            .shale => 1.4,
            .deepwater => 2.2,
            .arctic => 2.8,
        };
    }
    
    /// Get the environmental impact factor
    pub fn getEnvironmentalImpact(self: OilFieldType) f32 {
        return switch (self) {
            .onshore => 1.0,
            .offshore => 1.5,
            .shale => 2.0,
            .deepwater => 1.8,
            .arctic => 2.5,
        };
    }
};

/// Enhanced oil field with tycoon-specific features
pub const EnhancedOilField = struct {
    base: OilField,
    field_type: OilFieldType,
    purchase_price: f32,
    exploration_level: f32, // 0.0 to 1.0, affects certainty of estimates
    environmental_protection: f32, // 0.0 to 1.0, reduces environmental impact
    operational_efficiency: f32, // 0.0 to 2.0, affects operational costs
    staff_level: u32, // Number of staff assigned, affects extraction rate
    equipment_level: u32, // Quality of equipment, affects extraction quality and risk
    maintenance_level: f32, // 0.0 to 1.0, affects reliability and operational life
    
    /// Initialize a new enhanced oil field
    pub fn init(base_field: OilField, field_type: OilFieldType, purchase_price: f32) EnhancedOilField {
        return EnhancedOilField{
            .base = base_field,
            .field_type = field_type,
            .purchase_price = purchase_price,
            .exploration_level = 0.5,
            .environmental_protection = 0.2,
            .operational_efficiency = 1.0,
            .staff_level = 1,
            .equipment_level = 1,
            .maintenance_level = 0.5,
        };
    }
    
    /// Calculate the operational cost per day
    pub fn getOperationalCost(self: *const EnhancedOilField) f32 {
        const base_cost = 1000.0 + (self.base.max_capacity / 100.0);
        const type_multiplier = self.field_type.getOperationalCostMultiplier();
        const staff_cost = @as(f32, @floatFromInt(self.staff_level)) * 500.0;
        const equipment_cost = @as(f32, @floatFromInt(self.equipment_level)) * 300.0;
        const maintenance_cost = self.maintenance_level * 1000.0;
        
        // Higher efficiency reduces costs
        const efficiency_factor = 2.0 - self.operational_efficiency;
        
        return (base_cost * type_multiplier + staff_cost + equipment_cost + maintenance_cost) * efficiency_factor;
    }
    
    /// Calculate the daily extraction amount with all factors considered
    pub fn calculateDailyExtraction(self: *EnhancedOilField) f32 {
        if (self.base.oil_amount <= 0.0) return 0.0;
        
        // Base extraction rate with quality factor
        var base_rate = self.base.extraction_rate * self.base.quality;
        
        // Staff bonus
        base_rate *= 1.0 + (@as(f32, @floatFromInt(self.staff_level - 1)) * 0.1);
        
        // Equipment bonus
        base_rate *= 1.0 + (@as(f32, @floatFromInt(self.equipment_level - 1)) * 0.15);
        
        // Maintenance affects reliability (prevent some extraction if poor maintenance)
        const maintenance_factor = 0.5 + (self.maintenance_level * 0.5);
        base_rate *= maintenance_factor;
        
        // Limited by remaining oil
        return @min(base_rate, self.base.oil_amount);
    }
    
    /// Extract oil for one day, handling all the complex factors
    pub fn extractDaily(self: *EnhancedOilField) f32 {
        const amount_to_extract = self.calculateDailyExtraction();
        
        // Check for extraction incidents based on risk factor
        const risk = self.field_type.getRiskFactor() * (1.0 - self.maintenance_level);
        
        // Simple deterministic approach for demo (real game would use random)
        const day_of_month = @mod(@as(u32, @intFromFloat(self.base.oil_amount)) / 10, 30);
        const incident_occurs = day_of_month < @as(u32, @intFromFloat(risk * 100.0));
        
        var actual_extracted = amount_to_extract;
        
        if (incident_occurs) {
            // Incident reduces extraction
            actual_extracted *= 0.5;
        }
        
        // Update the base oil field
        self.base.oil_amount -= actual_extracted;
        if (self.base.oil_amount < 0.0) self.base.oil_amount = 0.0;
        
        return actual_extracted;
    }
    
    /// Invest in exploration to improve knowledge of the field
    pub fn investInExploration(self: *EnhancedOilField, amount: f32) void {
        // Each $10,000 improves exploration by 0.1 up to a maximum of 1.0
        const improvement = amount / 100000.0;
        self.exploration_level += improvement;
        if (self.exploration_level > 1.0) self.exploration_level = 1.0;
    }
    
    /// Invest in environmental protection
    pub fn investInEnvironmentalProtection(self: *EnhancedOilField, amount: f32) void {
        // Each $20,000 improves protection by 0.1 up to a maximum of 1.0
        const improvement = amount / 200000.0;
        self.environmental_protection += improvement;
        if (self.environmental_protection > 1.0) self.environmental_protection = 1.0;
    }
    
    /// Invest in operational efficiency
    pub fn investInEfficiency(self: *EnhancedOilField, amount: f32) void {
        // Each $15,000 improves efficiency by 0.1 up to a maximum of 2.0
        const improvement = amount / 150000.0;
        self.operational_efficiency += improvement;
        if (self.operational_efficiency > 2.0) self.operational_efficiency = 2.0;
    }
    
    /// Increase staff level
    pub fn increaseStaff(self: *EnhancedOilField, amount: u32) void {
        self.staff_level += amount;
        // Cap at reasonable level
        if (self.staff_level > 10) self.staff_level = 10;
    }
    
    /// Upgrade equipment
    pub fn upgradeEquipment(self: *EnhancedOilField, levels: u32) void {
        self.equipment_level += levels;
        // Cap at reasonable level
        if (self.equipment_level > 10) self.equipment_level = 10;
    }
    
    /// Perform maintenance
    pub fn performMaintenance(self: *EnhancedOilField, amount: f32) void {
        // Each $5,000 improves maintenance by 0.1 up to a maximum of 1.0
        const improvement = amount / 50000.0;
        self.maintenance_level += improvement;
        if (self.maintenance_level > 1.0) self.maintenance_level = 1.0;
    }
    
    /// Calculate the current market value of this field
    pub fn calculateMarketValue(self: *const EnhancedOilField, current_oil_price: f32) f32 {
        const remaining_oil_value = self.base.oil_amount * current_oil_price * 0.8;
        const infrastructure_value = 
            (@as(f32, @floatFromInt(self.staff_level)) * 10000.0) + 
            (@as(f32, @floatFromInt(self.equipment_level)) * 20000.0) +
            (self.maintenance_level * 30000.0) +
            (self.environmental_protection * 50000.0);
        
        return remaining_oil_value + infrastructure_value;
    }
}; 