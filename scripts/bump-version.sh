#!/usr/bin/env bash
# Bump MARKETING_VERSION and CURRENT_PROJECT_VERSION in Compresso.xcodeproj.
# Usage: ./scripts/bump-version.sh [patch|minor|major]

set -euo pipefail

PBXPROJ="Compresso.xcodeproj/project.pbxproj"
BUMP_TYPE="${1:-patch}"

if [ ! -f "$PBXPROJ" ]; then
  echo "::error::Project file not found: $PBXPROJ" >&2
  exit 1
fi

CURRENT_VERSION=$(grep -m1 'MARKETING_VERSION' "$PBXPROJ" | sed 's/.*= //' | sed 's/;.*//' | tr -d ' ')
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | sed 's/.*= //' | sed 's/;.*//' | tr -d ' ')

if [ -z "$CURRENT_VERSION" ] || [ -z "$CURRENT_BUILD" ]; then
  echo "::error::Could not find version settings in $PBXPROJ" >&2
  exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
MAJOR="${MAJOR:-0}"
MINOR="${MINOR:-0}"
PATCH="${PATCH:-0}"

case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "::error::Invalid bump type: $BUMP_TYPE. Use patch, minor, or major." >&2
    exit 1
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
NEW_BUILD=$((CURRENT_BUILD + 1))

TMP_FILE="${PBXPROJ}.tmp"
sed \
  -e "s/MARKETING_VERSION = ${CURRENT_VERSION}/MARKETING_VERSION = ${NEW_VERSION}/g" \
  -e "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD}/CURRENT_PROJECT_VERSION = ${NEW_BUILD}/g" \
  "$PBXPROJ" > "$TMP_FILE"
mv "$TMP_FILE" "$PBXPROJ"

echo "version=${NEW_VERSION}"
echo "previous_version=${CURRENT_VERSION}"
echo "build_number=${NEW_BUILD}"
