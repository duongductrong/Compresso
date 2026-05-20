#!/usr/bin/env bash
# Generate release notes from conventional commit subjects.
# Usage: ./scripts/generate-changelog.sh [previous_tag]

set -euo pipefail

PREVIOUS_TAG="${1:-}"

if [ -z "$PREVIOUS_TAG" ]; then
  PREVIOUS_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
fi

if [ -n "$PREVIOUS_TAG" ]; then
  RANGE="${PREVIOUS_TAG}..HEAD"
else
  RANGE="HEAD"
fi

collect() {
  local grep_pattern="$1"
  git log "$RANGE" --pretty=format:"%s (%h)" --grep="$grep_pattern" 2>/dev/null || true
}

FEATURES=$(collect '^feat')
FIXES=$(collect '^fix')
MAINTENANCE=$(collect '^chore\|^refactor\|^perf\|^style\|^ci\|^docs\|^build')
ALL_CHANGES=$(git log "$RANGE" --pretty=format:"%s (%h)" 2>/dev/null || true)
CONTRIBUTORS=$(git log "$RANGE" --pretty=format:"%an" 2>/dev/null | sort -u | sed 's/^/- @/' || true)

print_section() {
  local title="$1"
  local content="$2"

  if [ -z "$content" ]; then
    return
  fi

  printf '### %s\n' "$title"
  while IFS= read -r line; do
    [ -n "$line" ] && printf -- '- %s\n' "$line"
  done <<< "$content"
  printf '\n'
}

if [ -n "$FEATURES$FIXES$MAINTENANCE" ]; then
  print_section "Features" "$FEATURES"
  print_section "Bug Fixes" "$FIXES"
  print_section "Maintenance" "$MAINTENANCE"
else
  print_section "Changes" "$ALL_CHANGES"
fi

if [ -n "$CONTRIBUTORS" ]; then
  printf '### Contributors\n'
  printf '%s\n' "$CONTRIBUTORS"
fi
