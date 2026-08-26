# Ensure we're building with JDK 17 — Capacitor 5's scaffolded Gradle wrapper (8.0.x)
# can't read bytecode from newer JDKs (e.g. 21), which fails with a cryptic
# "Unsupported class file major version" error that has nothing to do with the plugin.
if /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
  export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
  echo "Using JDK 17 at $JAVA_HOME"
else
  echo "ERROR: JDK 17 not found. Install one, e.g.: brew install openjdk@17" >&2
  exit 1
fi

# 1. Build and pack the plugin from your current checkout
npm ci
npm run build
TARBALL="$(pwd)/$(npm pack --silent)"
echo "Packed: $TARBALL"

# 2. Scaffold a throwaway Capacitor 5 host app
rm -rf /tmp/cap5-host
mkdir -p /tmp/cap5-host/www
cd /tmp/cap5-host
npm init -y
npm install --save-exact \
  @capacitor/core@5.2.3 \
  @capacitor/cli@5.2.3 \
  @capacitor/android@5.2.3
echo "<html><body>compat check</body></html>" > www/index.html
npx cap init "Cap5Host" "com.example.cap5host" --web-dir=www
npx cap add android

# 3. Install the plugin tarball you just built
npm install "$TARBALL"
npx cap sync android

# 4. Build it
cd android
chmod +x ./gradlew
./gradlew assembleDebug --stacktrace