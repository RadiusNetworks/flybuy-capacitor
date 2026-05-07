#!/bin/bash
set -e

echo "========================================"
echo " flybuy-capacitor — Dev Setup (macOS)"
echo "========================================"
echo ""

REPO_ROOT="$(dirname "$0")/.."

# ── Homebrew ─────────────────────────────────────────────────────────────────
echo "🍺 Checking Homebrew..."
if ! command -v brew &> /dev/null; then
  echo "   Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "   Homebrew already installed ✓"
fi

# ── Node.js ───────────────────────────────────────────────────────────────────
echo ""
echo "📦 Checking Node.js..."
if ! command -v node &> /dev/null; then
  echo "   Installing Node.js via Homebrew..."
  brew install node@20
  brew link node@20
else
  NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
  if [ "$NODE_VERSION" -lt 20 ]; then
    echo "   ⚠️  Node.js $NODE_VERSION detected — version 20+ required"
    echo "   Installing Node.js 20..."
    brew install node@20
    brew link node@20 --force
  else
    echo "   Node.js $(node -v) already installed ✓"
  fi
fi

# ── CocoaPods ────────────────────────────────────────────────────────────────
echo ""
echo "🦺 Checking CocoaPods..."
if ! command -v pod &> /dev/null; then
  echo "   Installing CocoaPods..."
  brew install cocoapods
else
  echo "   CocoaPods $(pod --version) already installed ✓"
fi

# ── Java 17 ──────────────────────────────────────────────────────────────────
echo ""
echo "☕ Checking Java..."
if ! command -v java &> /dev/null; then
  echo "   Installing Java 17..."
  brew install openjdk@17
  sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
else
  JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
  if [ "$JAVA_VERSION" -lt 17 ]; then
    echo "   ⚠️  Java $JAVA_VERSION detected — version 17+ required"
    echo "   Installing Java 17..."
    brew install openjdk@17
    sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
  else
    echo "   Java $(java -version 2>&1 | head -1) already installed ✓"
  fi
fi

# ── Xcode CLI Tools ───────────────────────────────────────────────────────────
echo ""
echo "🔨 Checking Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
  echo "   Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "   ⚠️  Please complete the Xcode CLI tools installation and re-run this script"
  exit 1
else
  echo "   Xcode CLI tools already installed ✓"
fi

# ── npm dependencies ──────────────────────────────────────────────────────────
echo ""
echo "📦 Installing npm dependencies..."
cd "$REPO_ROOT"
npm install
echo "   npm dependencies installed ✓"

# ── iOS CocoaPods ─────────────────────────────────────────────────────────────
echo ""
echo "🍎 Installing iOS CocoaPods..."
if [ -f "ios/Plugin/Podfile" ]; then
  cd ios/Plugin
  pod install
  cd "$OLDPWD"
  echo "   CocoaPods installed ✓"
else
  echo "   ⚠️  ios/Plugin/Podfile not found — skipping pod install"
fi

# ── Android ───────────────────────────────────────────────────────────────────
echo ""
echo "🤖 Checking Android setup..."
if ! command -v sdkmanager &> /dev/null; then
  echo "   ⚠️  Android SDK not found"
  echo "   Please install Android Studio from https://developer.android.com/studio"
  echo "   Then install SDK Platform 35 via Android Studio → SDK Manager"
else
  echo "   Android SDK found ✓"
fi

# ── Verify Gradle wrapper ─────────────────────────────────────────────────────
echo ""
echo "🐘 Checking Gradle wrapper..."
if [ -f "android/gradlew" ]; then
  chmod +x android/gradlew
  echo "   Gradle wrapper found ✓"
else
  echo "   ⚠️  android/gradlew not found — run 'gradle wrapper' from android/"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "✅ Dev environment setup complete!"
echo ""
echo "Next steps:"
echo "  • Run all CI checks:  ./scripts/ci.sh"
echo "  • Run iOS CI:         ./scripts/ci-ios.sh"
echo "  • Open iOS in Xcode:  open ios/Plugin/Plugin.xcworkspace"
echo "  • Open Android:       open android/ in Android Studio"
echo "========================================"