#!/bin/bash
# Script to check for memory leaks in the TURMOIL project

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running memory leak checks for TURMOIL...${NC}"
echo 

# Move to project root directory
cd "$(dirname "$0")/.."

# Ensure build is up to date
echo -e "${YELLOW}Building project...${NC}"
zig build
echo -e "${GREEN}Build successful!${NC}"
echo

# Run tests to ensure everything is working
echo -e "${YELLOW}Running tests...${NC}"
zig build test
echo -e "${GREEN}Tests passed!${NC}"
echo

# Run benchmarks and check for memory leaks
echo -e "${YELLOW}Running benchmarks to check for memory leaks...${NC}"
BENCHMARK_OUTPUT=$(zig build benchmark 2>&1)
LEAK_CHECK=$(echo "$BENCHMARK_OUTPUT" | grep -i "leak" || true)

if [ -n "$LEAK_CHECK" ]; then
    echo -e "${RED}Memory leaks detected:${NC}"
    echo "$LEAK_CHECK"
    echo
    echo -e "${RED}Please fix memory leaks before committing!${NC}"
    exit 1
else
    echo -e "${GREEN}No memory leaks detected!${NC}"
fi

echo
echo -e "${GREEN}All checks passed! Ready to commit.${NC}"

# Make the script executable
chmod +x "$(dirname "$0")/check_memory.sh" 