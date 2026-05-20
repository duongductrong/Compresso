#!/usr/bin/env bash
# Prepend a Sparkle appcast item for a released Droplit DMG.
# Usage: ./scripts/update-appcast.sh <version> <build_number> <dmg_path> [appcast_file] [ed_signature] [release_notes_html]

set -euo pipefail

VERSION="${1:?Usage: update-appcast.sh <version> <build_number> <dmg_path> [appcast_file] [ed_signature] [release_notes_html]}"
BUILD_NUMBER="${2:?Usage: update-appcast.sh <version> <build_number> <dmg_path> [appcast_file] [ed_signature] [release_notes_html]}"
DMG_PATH="${3:?Usage: update-appcast.sh <version> <build_number> <dmg_path> [appcast_file] [ed_signature] [release_notes_html]}"
APPCAST_FILE="${4:-appcast.xml}"
ED_SIGNATURE="${5:-}"
RELEASE_NOTES_HTML="${6:-}"

if [ ! -f "$DMG_PATH" ]; then
  echo "::error::DMG file not found: $DMG_PATH" >&2
  exit 1
fi

if [ ! -f "$APPCAST_FILE" ]; then
  echo "::error::Appcast file not found: $APPCAST_FILE" >&2
  exit 1
fi

if [ -z "$ED_SIGNATURE" ] && [ "${ALLOW_UNSIGNED_APPCAST_ITEM:-false}" != "true" ]; then
  echo "::error::Sparkle EdDSA signature is required for release appcast items" >&2
  exit 1
fi

if stat -f%z "$DMG_PATH" >/dev/null 2>&1; then
  FILE_SIZE=$(stat -f%z "$DMG_PATH")
else
  FILE_SIZE=$(stat -c%s "$DMG_PATH")
fi

PUB_DATE=$(date -u '+%a, %d %b %Y %H:%M:%S +0000')
DOWNLOAD_URL="https://github.com/duongductrong/Droplit/releases/download/v${VERSION}/Droplit-v${VERSION}.dmg"

if [ -z "$RELEASE_NOTES_HTML" ]; then
  RELEASE_NOTES_HTML="<h3>Maintenance</h3><ul><li>Bug fixes and improvements</li></ul>"
fi

STYLE_BLOCK='<style>:root { color-scheme: light dark; } body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; font-size: 13px; line-height: 1.5; padding: 8px 16px; } h3 { font-size: 14px; margin: 12px 0 6px; } ul { padding-left: 20px; margin: 4px 0; } li { margin: 3px 0; }</style>'
ITEM_FILE="${APPCAST_FILE}.item.tmp"

cat > "$ITEM_FILE" <<EOF
    <item>
      <title>Version ${VERSION}</title>
      <sparkle:version>${BUILD_NUMBER}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>11.0</sparkle:minimumSystemVersion>
      <pubDate>${PUB_DATE}</pubDate>
      <description><![CDATA[
        ${STYLE_BLOCK}
        ${RELEASE_NOTES_HTML}
      ]]></description>
      <enclosure
        url="${DOWNLOAD_URL}"
        sparkle:edSignature="${ED_SIGNATURE}"
        length="${FILE_SIZE}"
        type="application/octet-stream"/>
    </item>
EOF

LANG_LINE=$(grep -n '<language>' "$APPCAST_FILE" | head -1 | cut -d: -f1)
if [ -z "$LANG_LINE" ]; then
  rm -f "$ITEM_FILE"
  echo "::error::Could not find <language> tag in $APPCAST_FILE" >&2
  exit 1
fi

{
  head -n "$LANG_LINE" "$APPCAST_FILE"
  cat "$ITEM_FILE"
  tail -n +"$((LANG_LINE + 1))" "$APPCAST_FILE"
} > "${APPCAST_FILE}.tmp"

mv "${APPCAST_FILE}.tmp" "$APPCAST_FILE"
rm -f "$ITEM_FILE"

echo "Updated $APPCAST_FILE with v${VERSION} build ${BUILD_NUMBER}"
