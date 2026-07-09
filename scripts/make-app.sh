#!/bin/bash
# Build SizeEnforcer and assemble a signed .app bundle.
#
# Usage: scripts/make-app.sh [output-dir]
#   output-dir defaults to ./build
set -euo pipefail

APP_NAME="SizeEnforcer"
BUNDLE_ID="com.example.dayflower.SizeEnforcer"
MIN_MACOS="15.0"
APP_ICON="AppIcon"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/build}"
APP_DIR="$OUT_DIR/$APP_NAME.app"

cd "$ROOT_DIR"

# Build with the Swift Build engine (`--build-system swiftbuild`), the same
# engine Xcode uses. Unlike the default `native` build system, it compiles the
# asset catalog that holds the tray icon into a loadable `Assets.car` and emits a
# properly structured resource bundle (Contents/Resources/Assets.car +
# Info.plist). It still needs a full Xcode for actool; select it with
# `xcode-select -s` or DEVELOPER_DIR.
BUILD_FLAGS=(--build-system swiftbuild -c release --arch arm64)
echo "==> Building (release, swiftbuild)…"
swift build "${BUILD_FLAGS[@]}"
PRODUCTS_DIR="$(swift build "${BUILD_FLAGS[@]}" --show-bin-path)"
BIN_PATH="$PRODUCTS_DIR/$APP_NAME"

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"

# Copy SwiftPM resource bundles (e.g. the tray icon) into Contents/Resources,
# where the generated `Bundle.module` accessor looks first
# (Bundle.main.resourceURL). Each bundle already carries a compiled Assets.car.
for bundle in "$PRODUCTS_DIR"/*.bundle; do
    [ -e "$bundle" ] || continue
    cp -R "$bundle" "$APP_DIR/Contents/Resources/"
done

# Compile the Icon Composer app icon (design/AppIcon.icon) into the bundle.
# actool emits a compiled Assets.car (holding the icon) plus a fallback
# AppIcon.icns into Contents/Resources; the referencing CFBundleIcon* keys are
# added to Info.plist below. This Assets.car is distinct from the SwiftPM
# resource bundle's own Assets.car (the tray icon), which lives one level deeper.
echo "==> Compiling app icon (actool)"
xcrun actool "$ROOT_DIR/design/$APP_ICON.icon" \
    --compile "$APP_DIR/Contents/Resources" \
    --app-icon "$APP_ICON" \
    --output-partial-info-plist "$OUT_DIR/actool-partial.plist" \
    --platform macosx \
    --minimum-deployment-target "$MIN_MACOS" \
    --output-format human-readable-text

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
    <key>CFBundleIconFile</key>
    <string>$APP_ICON</string>
    <key>CFBundleIconName</key>
    <string>$APP_ICON</string>
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
