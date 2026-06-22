#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="AccessControls"
APP_DIR="$ROOT_DIR/build/${APP_NAME}.app"
EXECUTABLE_PATH="$ROOT_DIR/.build/release/${APP_NAME}"
STATUS_ICON_PATH="$ROOT_DIR/Sources/AccessControlsApp/Resources/AccessControlsStatusIcon.png"

cd "$ROOT_DIR"
swift build -c release --product "$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/AppBundle/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/AppBundle/AccessControls.icns" "$APP_DIR/Contents/Resources/AccessControls.icns"
cp "$STATUS_ICON_PATH" "$APP_DIR/Contents/Resources/AccessControlsStatusIcon.png"

plutil -lint "$APP_DIR/Contents/Info.plist"
codesign --force --deep --sign - "$APP_DIR" >/dev/null
touch "$APP_DIR" "$APP_DIR/Contents/Info.plist" "$APP_DIR/Contents/Resources/AccessControls.icns" "$APP_DIR/Contents/Resources/AccessControlsStatusIcon.png"

echo "$APP_DIR"
