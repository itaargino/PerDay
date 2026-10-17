#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun swift-format lint --strict --recursive PerDay Tests Package.swift
PERDAY_SWIFT_HOST="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host"
xcrun swift -I "$PERDAY_SWIFT_HOST" -L "$PERDAY_SWIFT_HOST" \
  -Xlinker -rpath -Xlinker "$PERDAY_SWIFT_HOST" Scripts/check-style.swift
