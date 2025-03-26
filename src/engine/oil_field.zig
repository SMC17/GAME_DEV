const std = @import("std");

/// Structure representing an oil field with extraction properties.
pub const OilField = struct {
    oil_amount: f32,
    extraction_rate: f32,
    max_capacity: f32,
    quality: f32, // higher quality means more efficient extraction
    depth: f32, // affects difficulty of extraction
    
    /// Create a new oil field with default parameters
    pub fn init(initial_amount: f32, rate: f32) OilField {
        return OilField{
            .oil_amount = initial_amount,
            .extraction_rate = rate,
            .max_capacity = initial_amount,
            .quality = 1.0,
            .depth = 1.0,
        };
    }

    /// Simulates oil extraction over a given time delta.
    /// Returns the amount extracted and updates the remaining oil.
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
    
    /// Returns the percentage of oil remaining in the field
    pub fn getPercentageFull(self: *const OilField) f32 {
        return self.oil_amount / self.max_capacity;
    }
    
    /// Upgrade the extraction rate by a given amount
    pub fn upgradeExtractionRate(self: *OilField, amount: f32) void {
        self.extraction_rate += amount;
    }
}; 