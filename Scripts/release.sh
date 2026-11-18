#!/bin/bash
# Builds a universal, ad-hoc signed Doppio.app and zips it into dist/.
# Usage: Scripts/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(sed -n 's/.*MARKETING_VERSION: "\(.*\)"/\1/p' project.yml)
APP=build/Build/Products/Release/Doppio.app
ZIP="dist/Doppio-$VERSION.zip"

xcodegen generate
xcodebuild -project Doppio.xcodeproj -scheme Doppio -configuration Release \
  -derivedDataPath build -destination 'generic/platform=macOS' \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO clean build

# Ad-hoc signature: no Apple Developer identity, so the app is not notarized.
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

mkdir -p dist
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "Built $ZIP ($(lipo -archs "$APP/Contents/MacOS/Doppio"))"
shasum -a 256 "$ZIP"
