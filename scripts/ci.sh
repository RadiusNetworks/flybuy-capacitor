#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"

echo "========================================"
echo " flybuy-capacitor — Local CI"
echo "========================================"

bash "$SCRIPT_DIR/check-build.sh"
echo ""
bash "$SCRIPT_DIR/check-ts.sh"
echo ""
bash "$SCRIPT_DIR/check-lint.sh"
echo ""
bash "$SCRIPT_DIR/check-audit.sh"
echo ""
bash "$SCRIPT_DIR/check-android.sh"

echo ""
echo "========================================"
echo "✅ All checks passed!"
echo "========================================"