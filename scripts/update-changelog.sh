#!/usr/bin/env bash
# Prepend a versioned changelog entry.
# Usage: ./scripts/update-changelog.sh <version> <content_file> [changelog_file]

set -euo pipefail

VERSION="${1:?Usage: update-changelog.sh <version> <content_file> [changelog_file]}"
CONTENT_FILE="${2:?Usage: update-changelog.sh <version> <content_file> [changelog_file]}"
CHANGELOG_FILE="${3:-CHANGELOG.md}"

if [ ! -f "$CONTENT_FILE" ]; then
  echo "::error::Content file not found: $CONTENT_FILE" >&2
  exit 1
fi

if [ ! -f "$CHANGELOG_FILE" ]; then
  echo "::error::Changelog file not found: $CHANGELOG_FILE" >&2
  exit 1
fi

CONTENT=$(cat "$CONTENT_FILE")
if [ -z "$CONTENT" ]; then
  echo "::warning::Changelog content is empty; skipping update" >&2
  exit 0
fi

DATE=$(date +%Y-%m-%d)
NEW_ENTRY="## [${VERSION}] - ${DATE}

${CONTENT}"

FIRST_ENTRY_LINE=$(awk '/^## \[/{ print NR; exit }' "$CHANGELOG_FILE")

if [ -n "$FIRST_ENTRY_LINE" ]; then
  {
    head -n $((FIRST_ENTRY_LINE - 1)) "$CHANGELOG_FILE"
    printf '\n%s\n\n' "$NEW_ENTRY"
    tail -n +"$FIRST_ENTRY_LINE" "$CHANGELOG_FILE"
  } > "${CHANGELOG_FILE}.tmp"
else
  {
    cat "$CHANGELOG_FILE"
    printf '\n%s\n' "$NEW_ENTRY"
  } > "${CHANGELOG_FILE}.tmp"
fi

mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"
echo "Updated $CHANGELOG_FILE with v${VERSION}"
