# TURMOIL: Tycoon Mode Enhancement

## Market Simulation Feature

This document describes the economic market simulation component added to Tycoon Mode in TURMOIL.

### Overview

The market simulation provides a realistic and dynamic oil industry environment with:

1. Supply and demand dynamics that influence oil prices
2. Competing oil companies with unique strategies and behaviors
3. Random world events that impact market conditions
4. Visual charting for tracking price and demand trends

### Key Components

#### MarketSimulation

The `MarketSimulation` struct manages the global oil market:

- **Global supply and demand**: Tracks global oil production and consumption in millions of barrels per day
- **Market volatility**: Controls how unpredictable price movements can be
- **Price history**: Records historical price data for trend analysis
- **Market conditions**: Dynamically changes between boom, stable, recession, and crisis states

#### Competitors

AI-controlled competitor companies:

- Each competitor has unique characteristics (aggressiveness, technological level, reputation)
- Competitors adjust production based on market conditions
- More aggressive competitors maintain high production even in downturns
- Production affects global supply/demand balance and your market share

#### World Events

Random events that impact the oil market:

- **Middle East Conflict**: Increases prices due to supply disruptions
- **Major Oil Spill**: Industry-wide reputation hit and slight price increase 
- **New Oil Field Discovery**: Decreases prices as global supply increases
- **Global Recession**: Significantly reduces demand and prices
- **Alternative Energy Breakthrough**: Reduces oil demand and prices

Events have varying durations and probabilities, creating an unpredictable market environment.

### User Interface Enhancements

- **Market Details Screen**: Provides comprehensive market information
- **Price and Demand Charts**: Visual line charts showing historical trends
- **Competitor Analysis**: Details on rival companies and their strategies
- **World Events Panel**: Real-time information about active world events

### Strategic Gameplay

The enhanced market simulation creates deeper strategic choices:

- **Timing production**: Adjust extraction rates based on market conditions
- **Strategic investments**: Focus on research during downturns, expand during booms
- **Market competition**: Monitor competitor behavior to find market opportunities
- **Risk management**: Prepare for and respond to market-changing world events

### Implementation Details

- **Memory Management**: All array lists use proper allocation and deallocation
- **Performance Optimization**: History data is capped to prevent memory growth
- **Modular Design**: Separate structs for market, competitors, and events
- **Error Handling**: Uses proper Zig error handling patterns

### Future Enhancements

Potential future improvements:

- **Stock market simulation**: Allow buying/selling competitor shares
- **Industry partnerships**: Form alliances with competitors
- **Futures contracts**: Lock in oil prices for future delivery
- **Political influence**: Lobby for favorable market conditions
- **Market manipulation**: Strategies to influence global oil prices

## Usage

To experience the enhanced market simulation:

1. Launch TURMOIL with `zig build run`
2. Select "Tycoon Mode" from the main menu
3. Use the "View Market Details" option to see the new market simulation features
4. Monitor the "Market Condition" and "Oil Price" indicators to track changing market conditions
5. Adjust your strategy based on market trends and competitor behavior

## Best Practices

The implementation follows Zig best practices:

- **Explicit memory management**: Proper allocation and deallocation
- **Error handling**: Consistent use of error propagation
- **Immutability**: Using `const` for variables that don't need to be mutable
- **Documentation**: Clear comments explaining each component's purpose
- **Modularity**: Well-defined responsibilities for each struct 