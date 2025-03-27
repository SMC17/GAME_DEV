# Contributing to TURMOIL

Thank you for your interest in contributing to TURMOIL! This document outlines our contribution process and standards.

## Pre-Push Checklist

Before pushing your changes to GitHub, please ensure you complete the following:

1. ✅ **Build passes**: Run `zig build` to ensure the project builds successfully
2. ✅ **Tests pass**: Run `zig build test-all` to verify all tests pass
3. ✅ **No memory leaks**: Run `zig build benchmark` to check for memory leaks
4. ✅ **Cross-platform compatibility**: Consider compatibility with Linux, Windows, and macOS
5. ✅ **Documentation updated**: Update relevant documentation to reflect your changes
6. ✅ **Changelog entry**: Add an entry to CHANGELOG.md in the [Unreleased] section
7. ✅ **Code standards**: Ensure your code follows our coding standards

## Coding Standards

1. **Memory Management**
   - Always accept an allocator parameter for functions that allocate memory
   - Properly free all allocations, using `defer` whenever appropriate
   - Use `defer` to ensure cleanup in error paths
   - Document memory ownership in function comments

2. **Error Handling**
   - Never ignore errors; either handle them or propagate them
   - Use explicit error sets for public APIs
   - Log errors with context to help with debugging

3. **Code Style**
   - Run `zig fmt` before committing code
   - Follow Zig idioms for nullability, error handling, and memory management
   - Keep functions focused on a single responsibility
   - Use clear, descriptive names for variables, functions, and types

4. **Platform Compatibility**
   - Use ASCII characters in terminal UI for cross-platform compatibility
   - Check platform-specific behavior when using file paths, system calls, etc.
   - Add conditionals for platform-specific code where necessary

## Memory Management in Zig

TURMOIL follows Zig's memory management patterns:

1. **Explicit Allocator Usage**
   - Functions that need to allocate memory should accept an allocator parameter
   - Structures that own allocations should store the allocator for later use
   - Avoid global allocators for better testability and error tracking

2. **Ownership and Lifecycle**
   - Clearly document who owns each allocation
   - Structures should have `deinit()` methods to free their resources
   - Use `defer` to ensure cleanup even in error paths

3. **String Handling**
   - Be careful with `allocPrint` - always free the result when done
   - Consider using fixed-size buffers when the size is known
   - Document when a function takes ownership of a string

4. **Resource Management**
   - Pair resource acquisition with release (files, memory, etc.)
   - Use `errdefer` to clean up resources on error paths
   - Consider using arena allocators for short-lived allocations

## Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the pre-push checklist
5. Submit a pull request

All pull requests will be reviewed according to our coding standards.

## Documentation

If you're adding new features, please update the documentation:

1. Update relevant README sections
2. Add or update docstrings in the code
3. Add a CHANGELOG entry in the appropriate section
4. If needed, update the documentation in the `docs/` directory

Thank you for contributing to TURMOIL! 