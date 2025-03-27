#!/bin/bash
# Script to install Git hooks for the TURMOIL project

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Installing Git hooks for TURMOIL...${NC}"

# Move to project root directory
cd "$(dirname "$0")/.."
ROOT_DIR=$(pwd)

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Run the memory check script
./scripts/check_memory.sh

# If the script exits with a non-zero status, prevent the commit
if [ $? -ne 0 ]; then
  echo "Memory leaks detected. Commit aborted."
  exit 1
fi

# All checks passed, allow the commit
exit 0
EOF

# Make the hook executable
chmod +x .git/hooks/pre-commit

echo -e "${GREEN}Git hooks installed successfully!${NC}"
echo -e "${YELLOW}The pre-commit hook will automatically check for memory leaks before each commit.${NC}"

# Make this script executable too
chmod +x "$ROOT_DIR/scripts/install_hooks.sh" 