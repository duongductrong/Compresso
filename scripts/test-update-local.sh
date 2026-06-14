#!/usr/bin/env bash
# Local E2E test for Compresso Sparkle updates.
#
# Usage:
#   export SPARKLE_PRIVATE_KEY_FILE=$HOME/.config/compresso/sparkle_private_key.pem
#   ./scripts/test-update-local.sh test-same
#   ./scripts/test-update-local.sh test-mismatch
#   ./scripts/test-update-local.sh clean

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="/tmp/test-compresso-sparkle-update"
CERT_NAME="${COMPRESSO_SIGNING_IDENTITY:-Compresso Self-Signed}"
INSTALL_PATH="/Applications/Compresso.app"
SERVER_PORT="${COMPRESSO_UPDATE_TEST_PORT:-8089}"

V1_VERSION="99.0.0"
V1_BUILD="990"
V2_VERSION="99.0.1"
V2_BUILD="991"

FEED_URL="http://localhost:${SERVER_PORT}/appcast.xml"

find_sign_update() {
  local bin
  bin=$(find "$TEST_DIR/DerivedData/SourcePackages/artifacts" -name sign_update -type f 2>/dev/null | head -1 || true)
  if [ -n "$bin" ]; then
    chmod +x "$bin" 2>/dev/null || true
    echo "$bin"
    return
  fi

  local source_dir="$TEST_DIR/DerivedData/SourcePackages/checkouts/Sparkle/sign_update"
  if [ -d "$source_dir" ]; then
    swift build --package-path "$source_dir" -c release >/dev/null
    local bin_path
    bin_path=$(swift build --package-path "$source_dir" -c release --show-bin-path)
    echo "$bin_path/sign_update"
    return
  fi

  echo ""
}

check_prereqs() {
  echo "Checking prerequisites..."

  if ! security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo "Missing signing identity: $CERT_NAME" >&2
    echo "Run: ./scripts/create-signing-cert.sh" >&2
    exit 1
  fi

  if [ -z "${SPARKLE_PRIVATE_KEY_FILE:-}" ] || [ ! -f "${SPARKLE_PRIVATE_KEY_FILE:-}" ]; then
    echo "SPARKLE_PRIVATE_KEY_FILE must point to the Sparkle EdDSA private key file." >&2
    exit 1
  fi
}

build_archive() {
  local archive_path="$TEST_DIR/archive/Compresso.xcarchive"

  if [ -d "$archive_path" ]; then
    echo "Reusing archive: $archive_path"
    return
  fi

  mkdir -p "$TEST_DIR/archive"
  echo "Building unsigned archive..."
  if ! xcodebuild archive \
    -project "$PROJECT_DIR/Compresso.xcodeproj" \
    -scheme Compresso \
    -configuration Release \
    -archivePath "$archive_path" \
    -derivedDataPath "$TEST_DIR/DerivedData" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    > "$TEST_DIR/archive/build.log" 2>&1; then
    tail -60 "$TEST_DIR/archive/build.log"
    exit 1
  fi
}

patch_info_plist() {
  local app_path="$1"
  local version="$2"
  local build="$3"
  local plist="$app_path/Contents/Info.plist"

  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build" "$plist"
  /usr/libexec/PlistBuddy -c "Set :SUFeedURL $FEED_URL" "$plist"
}

sign_sparkle_components() {
  local app_path="$1"
  local identity="$2"
  local sparkle="$app_path/Contents/Frameworks/Sparkle.framework"

  if [ ! -d "$sparkle" ]; then
    echo "Sparkle.framework not found in app bundle" >&2
    exit 1
  fi

  [ -d "$sparkle/Versions/B/XPCServices/Installer.xpc" ] && \
    codesign --force --sign "$identity" -o runtime --timestamp=none "$sparkle/Versions/B/XPCServices/Installer.xpc"
  [ -d "$sparkle/Versions/B/XPCServices/Downloader.xpc" ] && \
    codesign --force --sign "$identity" -o runtime --preserve-metadata=entitlements --timestamp=none "$sparkle/Versions/B/XPCServices/Downloader.xpc"
  [ -f "$sparkle/Versions/B/Autoupdate" ] && \
    codesign --force --sign "$identity" -o runtime --timestamp=none "$sparkle/Versions/B/Autoupdate"
  [ -d "$sparkle/Versions/B/Updater.app" ] && \
    codesign --force --sign "$identity" -o runtime --timestamp=none "$sparkle/Versions/B/Updater.app"

  codesign --force --sign "$identity" -o runtime --timestamp=none "$sparkle"
}

sign_app() {
  local app_path="$1"
  local identity="$2"

  sign_sparkle_components "$app_path" "$identity"
  codesign --force --sign "$identity" -o runtime --timestamp=none "$app_path"
  codesign --verify --deep --strict "$app_path" 2>&1 || true
  codesign -dr - "$app_path" 2>&1 | sed -n 's/^designated => //p'
}

prepare_version() {
  local label="$1"
  local version="$2"
  local build="$3"
  local identity="$4"
  local archive_path="$TEST_DIR/archive/Compresso.xcarchive"
  local app_path="$TEST_DIR/$label/Compresso.app"

  rm -rf "$TEST_DIR/$label"
  mkdir -p "$TEST_DIR/$label"
  ditto "$archive_path/Products/Applications/Compresso.app" "$app_path"

  echo "Preparing $label: v$version ($build), identity=$identity"
  patch_info_plist "$app_path" "$version" "$build"
  sign_app "$app_path" "$identity"
}

install_v1() {
  echo "Installing v1 to $INSTALL_PATH"
  killall Compresso >/dev/null 2>&1 || true
  rm -rf "$INSTALL_PATH"
  ditto "$TEST_DIR/v1/Compresso.app" "$INSTALL_PATH"
}

create_dmg() {
  local root="$TEST_DIR/server/dmg-root"
  local dmg_path="$TEST_DIR/server/Compresso-test.dmg"

  rm -rf "$root" "$dmg_path"
  mkdir -p "$root"
  ditto "$TEST_DIR/v2/Compresso.app" "$root/Compresso.app"
  ln -s /Applications "$root/Applications"
  hdiutil create -volname "Compresso Test" -srcfolder "$root" -ov -format UDZO "$dmg_path" >/dev/null
}

sign_dmg_eddsa() {
  local dmg_path="$TEST_DIR/server/Compresso-test.dmg"
  SIGN_UPDATE=$(find_sign_update)

  if [ -z "$SIGN_UPDATE" ] || [ ! -x "$SIGN_UPDATE" ]; then
    echo "Could not locate Sparkle sign_update. Build once first." >&2
    exit 1
  fi

  local output
  output=$("$SIGN_UPDATE" "$dmg_path" --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" 2>&1)
  ED_SIGNATURE=$(echo "$output" | grep 'sparkle:edSignature=' | cut -d'"' -f2)

  if [ -z "$ED_SIGNATURE" ]; then
    echo "$output"
    echo "Could not extract Sparkle EdDSA signature" >&2
    exit 1
  fi
}

generate_appcast() {
  local dmg_path="$TEST_DIR/server/Compresso-test.dmg"
  local appcast_path="$TEST_DIR/server/appcast.xml"
  local file_size
  local pub_date

  file_size=$(stat -f%z "$dmg_path")
  pub_date=$(date -u '+%a, %d %b %Y %H:%M:%S +0000')

  cat > "$appcast_path" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Compresso Test Updates</title>
    <link>http://localhost:${SERVER_PORT}</link>
    <description>Local test appcast</description>
    <language>en</language>
    <item>
      <title>Version ${V2_VERSION}</title>
      <sparkle:version>${V2_BUILD}</sparkle:version>
      <sparkle:shortVersionString>${V2_VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>11.0</sparkle:minimumSystemVersion>
      <pubDate>${pub_date}</pubDate>
      <enclosure
        url="http://localhost:${SERVER_PORT}/Compresso-test.dmg"
        sparkle:edSignature="${ED_SIGNATURE}"
        length="${file_size}"
        type="application/octet-stream"/>
    </item>
  </channel>
</rss>
EOF
}

start_server() {
  lsof -ti:"$SERVER_PORT" | xargs kill >/dev/null 2>&1 || true
  cd "$TEST_DIR/server"
  python3 -m http.server "$SERVER_PORT" &
  SERVER_PID=$!
  cd "$PROJECT_DIR"
  sleep 1

  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    echo "HTTP server failed to start" >&2
    exit 1
  fi
}

stop_server() {
  lsof -ti:"$SERVER_PORT" | xargs kill >/dev/null 2>&1 || true
}

run_test() {
  local mode="$1"
  local v2_identity="$CERT_NAME"

  if [ "$mode" = "mismatch" ]; then
    v2_identity="${COMPRESSO_MISMATCH_SIGNING_IDENTITY:--}"
  fi

  check_prereqs
  build_archive
  prepare_version "v1" "$V1_VERSION" "$V1_BUILD" "$CERT_NAME"
  prepare_version "v2" "$V2_VERSION" "$V2_BUILD" "$v2_identity"
  install_v1
  mkdir -p "$TEST_DIR/server"
  create_dmg
  sign_dmg_eddsa
  generate_appcast
  start_server

  echo
  echo "Local Sparkle test is ready."
  echo "Mode: $mode"
  echo "Installed: v$V1_VERSION ($V1_BUILD) at $INSTALL_PATH"
  echo "Available: v$V2_VERSION ($V2_BUILD)"
  echo "Appcast: http://localhost:$SERVER_PORT/appcast.xml"
  echo
  echo "Open Compresso from /Applications, then About -> Check for Updates."
  echo "Press Ctrl+C to stop the server."
  echo

  trap 'stop_server; exit 0' INT TERM
  wait "$SERVER_PID" 2>/dev/null || true
}

case "${1:-help}" in
  test-same)
    run_test "same"
    ;;
  test-mismatch)
    run_test "mismatch"
    ;;
  clean)
    stop_server
    killall Compresso >/dev/null 2>&1 || true
    rm -rf "$TEST_DIR"
    echo "Cleaned $TEST_DIR"
    ;;
  help|*)
    echo "Usage: $0 <test-same|test-mismatch|clean>"
    echo
    echo "Environment:"
    echo "  SPARKLE_PRIVATE_KEY_FILE       required Sparkle EdDSA private key file"
    echo "  COMPRESSO_SIGNING_IDENTITY       default: Compresso Self-Signed"
    echo "  COMPRESSO_MISMATCH_SIGNING_IDENTITY default: -"
    echo "  COMPRESSO_UPDATE_TEST_PORT       default: 8089"
    ;;
esac
