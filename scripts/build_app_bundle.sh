#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$PROJECT_DIR/build/MenuBarTimer.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_FILE="$PROJECT_DIR/assets/AppIcon.icns"

cd "$PROJECT_DIR"

swift build -c release

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp ".build/release/MenuBarTimer" "$MACOS_DIR/MenuBarTimer"

if [[ -f "$ICON_FILE" ]]; then
  cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MenuBarTimer</string>
  <key>CFBundleIdentifier</key>
  <string>local.codex.MenuBarTimer</string>
  <key>CFBundleName</key>
  <string>MenuBarTimer</string>
  <key>CFBundleDisplayName</key>
  <string>MenuBarTimer</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <false/>
</dict>
</plist>
PLIST

echo "Created $APP_DIR"
