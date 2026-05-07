# Contributing to flybuy-capacitor
 
## Prerequisites
 
- Node.js 20+
- npm 10+
- Android Studio (for Android development)
- Xcode 15+ with CocoaPods (for iOS development, macOS only)
- Java 17 (for Android builds)
---
 
## Setup
 
### Automated (recommended)
 
```bash
git clone https://github.com/RadiusNetworks/flybuy-capacitor.git
cd flybuy-capacitor
./scripts/setup-macos.sh
```
 
This installs Homebrew, Node.js 20, CocoaPods, Java 17, npm dependencies, and iOS pods in one shot.
 
### Manual
 
```bash
git clone https://github.com/RadiusNetworks/flybuy-capacitor.git
cd flybuy-capacitor
npm install
```
 
### iOS setup (first time only)
 
```bash
cd ios/Plugin
pod install
cd ../..
```
 
---
 
## Running CI Checks Locally
 
Use the scripts in the `scripts/` folder to run checks locally before pushing.
 
### Run all checks
 
```bash
./scripts/ci.sh        # JS/TS + Android
./scripts/ci-ios.sh    # iOS (macOS only)
```
 
### Run individual checks
 
```bash
./scripts/check-ts.sh      # TypeScript type check
./scripts/check-lint.sh    # ESLint
./scripts/check-build.sh   # Build dist
./scripts/check-audit.sh   # Security audit
./scripts/check-android.sh # Android compile
./scripts/check-ios.sh     # iOS compile (macOS only)
```
 
---
 
## Manual Commands
 
### TypeScript — Type Check
 
```bash
npx tsc --noEmit
```
 
### Lint
 
```bash
npm run lint
```
 
### Build
 
```bash
npm run build
```
 
### Security Audit
 
```bash
npm audit --audit-level=high
```
 
### Android — Compile Check
 
```bash
cd android && ./gradlew compileDebugKotlin
```
 
### Android — Full Build
 
```bash
cd android && ./gradlew build
```
 
### iOS — Compile Check
 
```bash
xcodebuild -workspace ios/Plugin/Plugin.xcworkspace \
           -scheme Plugin \
           -destination 'generic/platform=iOS' \
           build
```
 
---
 
## Common Issues
 
**`Project with path ':capacitor-android' could not be found`**
Run `npm install` from the repo root first — Capacitor Android is resolved from `node_modules`.
 
**`Minimum supported Gradle version is X`**
Update `android/gradle/wrapper/gradle-wrapper.properties` to use the required Gradle version.
 
**iOS pod install fails**
Make sure `npm install` has been run first, then `cd ios/Plugin && pod install`.
 
**iOS build fails after `npm install`**
Re-run `pod install` — CocoaPods paths may need to be refreshed after dependency updates.
 
---
 
## Release Process
 
Releases are created by pushing a version tag. Anyone on the team can cut a release:
 
```bash
# Bump version (choose patch, minor, or major)
npm version patch   # 0.1.0 → 0.1.1
npm version minor   # 0.1.0 → 0.2.0
 
# Push commit and tag
git push origin main --follow-tags
```
 
GitHub Actions will run the full CI suite and create a GitHub Release automatically.
 
### Installing a specific version in a host app
 
```bash
npm install github:RadiusNetworks/flybuy-capacitor#v0.2.0
```
 
---
 
## Project Structure
 
```
flybuy-capacitor/
├── src/                    # TypeScript source
│   ├── definitions.ts      # Plugin interface, enums, and types
│   ├── index.ts            # Plugin registration
│   └── web.ts              # Browser stubs (no-op)
├── ios/Plugin/
│   ├── Plugin.xcodeproj/
│   ├── Plugin.xcworkspace/ # Open this in Xcode (not .xcodeproj)
│   ├── Podfile
│   ├── FlybuyPlugin.swift  # iOS native implementation
│   ├── FlybuyPlugin.m      # Objective-C bridge
│   └── AppDelegate.example.swift
├── android/
│   ├── build.gradle
│   ├── settings.gradle
│   └── src/main/java/com/radiusnetworks/flybuy/capacitor/
│       └── FlybuyPlugin.kt # Android native implementation
├── android/examples/       # Example files to copy into host app
├── scripts/                # Local CI scripts
├── .github/
│   ├── workflows/
│   │   ├── ci.yml          # Type check, lint, build, Android compile
│   │   └── release.yml     # Triggered on version tags
│   └── dependabot.yml      # Automated dependency updates
└── README.md
```
 