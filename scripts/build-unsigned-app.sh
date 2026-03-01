#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT/dist"
APP_NAME="YT Skim"
APP_DIR="$DIST_DIR/${APP_NAME}.app"
PROJECT_DIR="$ROOT/YTSkimNative"
PROJECT_FILE="$PROJECT_DIR/YTSkimNative.xcodeproj"
SCHEME="YT Skim"
BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/YTSkimNative.xcarchive"

mkdir -p "$DIST_DIR"
mkdir -p "$BUILD_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Missing dependency: xcodegen (install with: brew install xcodegen)"
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Missing dependency: xcodebuild (install full Xcode and run xcode-select)"
  exit 1
fi

(
  cd "$PROJECT_DIR"
  xcodegen generate
)

rm -rf "$APP_DIR"

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  clean archive

SOURCE_APP="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"
if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Build completed but app was not found at: $SOURCE_APP"
  exit 1
fi

cp -R "$SOURCE_APP" "$APP_DIR"

echo "Built unsigned app at: $APP_DIR"
