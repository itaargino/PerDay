#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcodebuild -project PerDay.xcodeproj -scheme PerDay -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${PERDAY_APP_BUILD_DIR:-/private/tmp/perday-derived}" \
  CODE_SIGNING_ALLOWED=NO build
