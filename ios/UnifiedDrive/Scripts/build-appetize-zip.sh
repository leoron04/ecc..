#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/UnifiedDrive.xcodeproj"
SCHEME="UnifiedDrive"
CONFIGURATION="Release"
DERIVED_DATA="$PROJECT_ROOT/build/AppetizeDerivedData"
EXPORT_PATH="$PROJECT_ROOT/build/appetize"
BUNDLE_ID="${BUNDLE_ID:-com.local.UnifiedDrive}"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_DATA" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  ONLY_ACTIVE_ARCH=NO \
  build

APP_PATH="$(find "$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphonesimulator" -maxdepth 1 -name '*.app' -print -quit)"
if [ -z "$APP_PATH" ]; then
  echo "No simulator .app produced" >&2
  exit 1
fi

mkdir -p "$EXPORT_PATH"
PRODUCTS_DIR="$(dirname "$APP_PATH")"
APP_NAME="$(basename "$APP_PATH")"
(cd "$PRODUCTS_DIR" && zip -qry "$EXPORT_PATH/UnifiedDrive-Appetize-iOS-Simulator.zip" "$APP_NAME")

echo "$EXPORT_PATH/UnifiedDrive-Appetize-iOS-Simulator.zip"
