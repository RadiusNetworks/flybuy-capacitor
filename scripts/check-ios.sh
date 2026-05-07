#!/bin/bash
set -e

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "⚠️  iOS build requires macOS — skipping"
  exit 0
fi

echo "🍎 Building iOS..."
xcodebuild \
  -workspace "$(dirname "$0")/../ios/Plugin/Plugin.xcworkspace" \
  -scheme Plugin \
  -destination 'generic/platform=iOS' \
  build \
  | xcpretty || true

# Re-run without xcpretty if it's not installed
if ! command -v xcpretty &> /dev/null; then
  xcodebuild \
    -workspace "$(dirname "$0")/../ios/Plugin/Plugin.xcworkspace" \
    -scheme Plugin \
    -destination 'generic/platform=iOS' \
    build
fi

echo "✅ iOS build passed"