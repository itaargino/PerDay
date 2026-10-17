#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash Scripts/check-style.sh
bash Scripts/test.sh
bash Scripts/build.sh
