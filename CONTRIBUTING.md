# Contributing to flybuy-capacitor
 
## Prerequisites
 
- Node.js 20+
- npm 10+
- Android Studio (for Android development)
- Java 21 (required by `@capacitor/android` 8.x)
- Xcode 15+ (for iOS development, macOS only — SPM, no CocoaPods required)
---
 
## Setup
 
```bash
git clone https://github.com/RadiusNetworks/flybuy-capacitor.git
cd flybuy-capacitor
npm install
```
 
That's it — iOS dependencies are managed via Swift Package Manager and are resolved automatically when building.
 
---
 
## Running CI Checks Locally
 
Use the scripts in the `bin/` folder to run checks locally before pushing.
 
### Run all checks
 
```bash
./bin/ci        # JS/TS + Android
./bin/ci-ios    # iOS (macOS only)
```
 
### Run individual checks
 
```bash
./bin/check-ts      # TypeScript type check
./bin/check-lint    # ESLint
./bin/check-build   # Build dist
./bin/check-audit   # Security audit
./bin/check-android # Android compile
./bin/check-ios     # iOS compile (macOS only)
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
xcodebuild \
  -scheme FlybuyCapacitor \
  -destination "generic/platform=iOS Simulator" \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  build
```
 
---
 
## Common Issues
 
**`Project with path ':capacitor-android' could not be found`**
Run `npm install` from the repo root first — Capacitor Android is resolved from `node_modules`.
 
**`Minimum supported Gradle version is X`**
Update `android/gradle/wrapper/gradle-wrapper.properties` to use the required Gradle version.
 
**`error: invalid source release: 21`**
Java 21 is required. Install it with `brew install --cask zulu@21` and make sure `JAVA_HOME` points to it.
 
**iOS build fails with `no such module 'Capacitor'`**
Run `swift package resolve` from the repo root to fetch SPM dependencies.
 
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
│   ├── web.ts              # Browser stubs (no-op)
│   ├── pickup/             # Pickup module
│   └── notify/             # Notify module
├── ios/Plugin/
│   ├── FlybuyPlugin.swift          # iOS native implementation
│   ├── FlybuyPlugin.m              # Objective-C bridge
│   ├── FlybuyPickupPlugin.swift
│   ├── FlybuyPickupPlugin.m
│   ├── FlybuyNotifyPlugin.swift
│   ├── FlybuyNotifyPlugin.m
│   └── AppDelegate.example.swift   # Copy into host app AppDelegate
├── Package.swift           # Swift Package Manager manifest
├── android/
│   ├── build.gradle
│   ├── settings.gradle
│   └── src/main/java/com/radiusnetworks/flybuy/capacitor/
│       ├── FlybuyPlugin.kt         # Core — customer, sites, places, links, orders
│       ├── FlybuyPickupPlugin.kt   # Pickup — order events
│       └── FlybuyNotifyPlugin.kt   # Notify — campaigns
├── bin/                    # Local CI scripts
├── .github/
│   ├── workflows/
│   │   ├── ci.yml          # Type check, lint, build, Android compile
│   │   └── release.yml     # Triggered on version tags
│   └── dependabot.yml      # Automated dependency updates
└── README.md
```
 