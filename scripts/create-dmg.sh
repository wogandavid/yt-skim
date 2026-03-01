#!/usr/bin/env bash

set -euo pipefail

APP_PATH="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_APP_PATH="$ROOT/dist/YT Skim.app"
if [[ -z "$APP_PATH" ]]; then
  APP_PATH="$DEFAULT_APP_PATH"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH"
  echo "Usage: create-dmg.sh [/absolute/path/to/YT\\ Skim.app]"
  exit 1
fi

DIST_DIR="$ROOT/dist"
STAGE_DIR="$DIST_DIR/dmg-stage"
DMG_PATH="$DIST_DIR/YT-Skim-unsigned.dmg"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

cp -R "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "YT Skim" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE_DIR"

echo "Created unsigned DMG at: $DMG_PATH"
