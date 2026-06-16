#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/UnifiedDrive.xcodeproj"
SCHEME="UnifiedDrive"
CONFIGURATION="Release"
DERIVED_DATA="$PROJECT_ROOT/build/DerivedData"
EXPORT_PATH="$PROJECT_ROOT/build/export"
BUNDLE_ID="${BUNDLE_ID:-com.local.UnifiedDrive}"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="$(find "$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos" -maxdepth 1 -name '*.app' -print -quit)"
if [ -z "$APP_PATH" ]; then
  echo "No .app produced" >&2
  exit 1
fi

rm -rf "$PROJECT_ROOT/build/Payload" "$EXPORT_PATH"
mkdir -p "$PROJECT_ROOT/build/Payload" "$EXPORT_PATH"
cp -R "$APP_PATH" "$PROJECT_ROOT/build/Payload/"
(cd "$PROJECT_ROOT/build" && zip -qry "$EXPORT_PATH/UnifiedDrive-unsigned.ipa" Payload)

echo "$EXPORT_PATH/UnifiedDrive-unsigned.ipa"
