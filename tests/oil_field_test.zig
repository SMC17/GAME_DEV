const std = @import("std");
const oil_field = @import("../src/engine/oil_field.zig");
const testing = std.testing;

test "OilField.extract" {
    var field = oil_field.OilField.init(1000.0, 10.0);
    
    // Test single extraction
    const extracted1 = field.extract(1.0);
    try testing.expectEqual(@as(f32, 10.0), extracted1);
    try testing.expectEqual(@as(f32, 990.0), field.oil_amount);
    
    // Test multiple extractions
    const extracted2 = field.extract(5.0);
    try testing.expectEqual(@as(f32, 50.0), extracted2);
    try testing.expectEqual(@as(f32, 940.0), field.oil_amount);
    
    // Test extraction that would exceed remaining amount
    field.oil_amount = 20.0;
    const extracted3 = field.extract(3.0);
    try testing.expectEqual(@as(f32, 20.0), extracted3);
    try testing.expectEqual(@as(f32, 0.0), field.oil_amount);
}

test "OilField.getPercentageFull" {
    var field = oil_field.OilField.init(1000.0, 10.0);
    
    // Test full
    try testing.expectEqual(@as(f32, 1.0), field.getPercentageFull());
    
    // Test half full
    field.oil_amount = 500.0;
    try testing.expectEqual(@as(f32, 0.5), field.getPercentageFull());
    
    // Test empty
    field.oil_amount = 0.0;
    try testing.expectEqual(@as(f32, 0.0), field.getPercentageFull());
}

test "OilField.upgradeExtractionRate" {
    var field = oil_field.OilField.init(1000.0, 10.0);
    
    field.upgradeExtractionRate(5.0);
    try testing.expectEqual(@as(f32, 15.0), field.extraction_rate);
    
    field.upgradeExtractionRate(2.5);
    try testing.expectEqual(@as(f32, 17.5), field.extraction_rate);
} 