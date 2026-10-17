#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
swift test --scratch-path "${PERDAY_TEST_BUILD_DIR:-/private/tmp/perday-swift-tests}"
