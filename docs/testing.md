# TURMOIL Testing Architecture

This document outlines the testing architecture for the TURMOIL project, explaining the different types of tests, how they're organized, and how to run them.

## Test Types

TURMOIL uses several types of tests to ensure the quality and correctness of the codebase:

### Unit Tests

Unit tests verify the functionality of individual components in isolation. They're located alongside the source code they test and can be run using:

```bash
zig build test
```

Key unit tests:
- `tests/oil_field_test.zig`: Tests for the core OilField structure

### Integration Tests

Integration tests verify that different game modes and components work correctly together. Instead of importing the actual source files (which can cause module path issues in Zig 0.14.0), we use a mock-based approach that mimics the behavior of the real components while allowing for isolated testing.

Integration tests can be run using:

```bash
zig build test-integration
```

The main integration test file is `tests/integration_tests.zig`, which tests:
- Tycoon mode integration with the simulation engine
- Character progression affecting Campaign outcomes
- Arcade mode high scores being preserved in Sandbox mode

### UI Component Tests

UI component tests verify the functionality of the terminal UI components, ensuring they correctly render colors, styles, and UI elements like status bars and menus.

UI tests can be run using:

```bash
zig build test-ui
```

The main UI test file is `tests/ui_tests.zig`, which tests:
- Terminal UI color and style functionality
- Drawing UI elements (lines, titles)
- Drawing status bars with correct proportions
- Drawing menus with proper highlighting

### Performance Benchmarks

Performance benchmarks measure the execution time of critical game components to ensure they meet performance requirements.

Benchmarks can be run using:

```bash
zig build benchmark
```

The benchmark file is `tests/benchmarks.zig`, which measures:
- Core simulation performance
- Tycoon mode daily operations
- Arcade mode extraction and scoring
- Sandbox mode simulation

## Memory Management Testing

TURMOIL uses Zig's allocator pattern to manage memory. To ensure there are no memory leaks:

1. Always pair allocations with corresponding deallocations
2. Use defer statements to ensure cleanup even in error cases
3. Pass allocators down through function calls rather than using global allocators
4. Prefer stack allocations when possible
5. Be mindful of string duplication with allocPrint

We've implemented several best practices:
- The TerminalUI now consistently uses the provided allocator
- All UI components properly manage their allocations
- Temporary string buffers use the caller's allocator

## Character Encoding Best Practices

To ensure compatibility across platforms:
1. Use ASCII characters whenever possible for UI elements
2. Avoid Unicode box-drawing characters and special symbols
3. For internationalization, ensure proper UTF-8 handling
4. Test on different terminal implementations

## Running All Tests

You can run all tests (unit, integration, and UI) with a single command:

```bash
zig build test-all
```

## Continuous Integration

Tests are automatically run on GitHub Actions when changes are pushed to the repository, ensuring that all tests pass across different platforms (Linux, Windows, macOS).

## Writing New Tests

When adding new functionality, please follow these guidelines for testing:

1. **Unit Tests**: Add unit tests for all new functions and structures.
2. **Integration Tests**: If the new functionality interacts with existing game modes, add integration tests to verify correct interaction.
3. **UI Tests**: If the new functionality includes UI components, add UI tests.
4. **Performance Benchmarks**: If the new functionality is performance-critical, add performance benchmarks.

When writing tests that require importing modules, consider using a mock-based approach to avoid module path issues in Zig 0.14.0. 