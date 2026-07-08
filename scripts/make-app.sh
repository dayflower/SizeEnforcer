#!/bin/bash
# Build SizeEnforcer and assemble a signed .app bundle.
#
# Usage: scripts/make-app.sh [output-dir]
#   output-dir defaults to ./build
set -euo pipefail

APP_NAME="SizeEnforcer"
BUNDLE_ID="com.example.dayflower.SizeEnforcer"
MIN_MACOS="14.0"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/build}"
APP_DIR="$OUT_DIR/$APP_NAME.app"

cd "$ROOT_DIR"

echo "==> Building (release)…"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Code signing (ad-hoc)"
codesign --force --deep --sign - "$APP_DIR"

echo "==> Done: $APP_DIR"
