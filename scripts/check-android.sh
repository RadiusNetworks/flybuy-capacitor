#!/bin/bash
set -e
echo "🤖 Building Android..."
cd "$(dirname "$0")/../android"
./gradlew compileDebugKotlin
echo "✅ Android build passed"