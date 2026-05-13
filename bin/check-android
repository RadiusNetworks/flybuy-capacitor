#!/bin/bash
set -e
echo "🤖 Building Android..."
cd "$(dirname "$0")/../android"

# Use Java 21 if available
if [ -d "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home" ]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home"
elif command -v /usr/libexec/java_home &>/dev/null; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home)
fi

echo "☕ Using Java: $JAVA_HOME"
./gradlew compileDebugKotlin
echo "✅ Android build passed"