#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_APP="$PROJECT_DIR/build/MenuBarTimer.app"
APPLICATIONS_DIR="$HOME/Applications"
TARGET_APP="$APPLICATIONS_DIR/MenuBarTimer.app"

cd "$PROJECT_DIR"

"$PROJECT_DIR/scripts/build_app_bundle.sh"

mkdir -p "$APPLICATIONS_DIR"
ditto "$SOURCE_APP" "$TARGET_APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$TARGET_APP" >/dev/null 2>&1 || true
rm -rf "$SOURCE_APP"

echo "Installed $TARGET_APP"
