#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"

echo "========================================"
echo " flybuy-capacitor — iOS CI"
echo "========================================"

bash "$SCRIPT_DIR/check-ios.sh"

echo ""
echo "========================================"
echo "✅ iOS check passed!"
echo "========================================"