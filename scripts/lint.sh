#!/usr/bin/env bash
# Linting script for portable-bootstrap
# Run shellcheck on all shell scripts in the project

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

# Check if shellcheck is installed
if ! command -v shellcheck >/dev/null 2>&1; then
  error "shellcheck is not installed. Install it with: brew install shellcheck"
  exit 1
fi

cd "$PROJECT_ROOT"

log "Running shellcheck on all shell scripts..."

# Find all shell scripts and run shellcheck
EXIT_CODE=0
TOTAL_FILES=0
PASSED_FILES=0

while IFS= read -r -d '' file; do
  TOTAL_FILES=$((TOTAL_FILES + 1))
  echo "Checking: $file"
  
  if shellcheck "$file"; then
    PASSED_FILES=$((PASSED_FILES + 1))
  else
    EXIT_CODE=1
  fi
  echo
done < <(find . -name "*.sh" -type f -print0)

# Summary
echo "=================================="
if [ $EXIT_CODE -eq 0 ]; then
  log "All $TOTAL_FILES shell scripts passed shellcheck!"
else
  FAILED_FILES=$((TOTAL_FILES - PASSED_FILES))
  warn "$FAILED_FILES out of $TOTAL_FILES shell scripts have issues"
fi

exit $EXIT_CODE
