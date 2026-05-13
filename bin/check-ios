#!/bin/bash
set -e

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "⚠️  iOS build requires macOS — skipping"
  exit 0
fi

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PLUGIN_DIR"

# ── Validate Package.swift ────────────────────────────────────────────────────
echo "🍎 Validating Package.swift..."
swift package dump-package > /dev/null
echo "✅ Package.swift is valid"

# ── Resolve dependencies ──────────────────────────────────────────────────────
echo "🔄 Resolving packages..."
swift package resolve

# ── Build ─────────────────────────────────────────────────────────────────────
echo "🏗️  Building FlybuyCapacitor..."
xcodebuild \
  -scheme FlybuyCapacitor \
  -destination "generic/platform=iOS Simulator" \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  build \
  2>&1 | grep -E "error:|Build succeeded|BUILD FAILED" | grep -v "^$" || true

STATUS=${PIPESTATUS[0]}
if [ $STATUS -ne 0 ]; then
  echo "❌ iOS build failed"
  exit 1
fi

echo "✅ iOS build passed"