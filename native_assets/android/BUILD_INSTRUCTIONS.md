# �� Build Instructions for Native Watcher APK

## Quick Build

### Option 1: Use Build Script (Easiest)

```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/native_assets/android

./build_watcher.sh
```

### Option 2: Use Gradle Directly

```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/native_assets/android

./gradlew buildWatcherApk
```

### Option 3: Use Legacy Command (Backward Compatible)

```bash
./gradlew buildWatcherJar  # Same as buildWatcherApk
```

---

## Output Location

After successful build, the APK will be available at:

```
📦 build/libs/native_watcher.apk
```

This is the file used by your Flutter tests!

---

## What Gets Built?

The APK contains:

1. ✅ **NativeWatcher.java** - Main watcher logic
2. ✅ **Test-driven configuration** - Reads JSON from device
3. ✅ **Permission handlers** - Allow/Deny based on test config
4. ✅ **Location precision selector** - Precise/Approximate
5. ✅ **Google Sign-In handler** - Dismisses credential picker
6. ✅ **ANR handler** - Handles "App not responding"
7. ✅ **System dialog handlers** - OK, Continue, Got it, etc.

---

## Build Process

```
┌──────────────────────────────────────┐
│ ./gradlew buildWatcherApk            │
└────────────────┬─────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────┐
│ Step 1: Clean previous build         │
└────────────────┬─────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────┐
│ Step 2: Compile Java sources         │
│ • NativeWatcher.java                 │
│ • Configuration classes              │
└────────────────┬─────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────┐
│ Step 3: Build instrumentation APK    │
│ assembleDebugAndroidTest             │
└────────────────┬─────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────┐
│ Output:                              │
│ build/outputs/apk/androidTest/debug/ │
│ native_watcher-debug-androidTest.apk │
└────────────────┬─────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────┐
│ Step 4: Copy to build/libs/          │
│ Rename to: native_watcher.apk        │
└────────────────┬─────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────┐
│ ✅ Ready to use!                     │
│ build/libs/native_watcher.apk        │
└──────────────────────────────────────┘
```

---

## Prerequisites

### 1. Java 11+

```bash
java -version
# Should show: java version "11" or higher
```

### 2. Android SDK

```bash
# Check ANDROID_HOME is set
echo $ANDROID_HOME

# Should point to: ~/Library/Android/sdk
```

### 3. Gradle Wrapper (Already included)

```bash
# Check gradlew exists
ls -l gradlew

# Make it executable (if needed)
chmod +x gradlew
```

---

## First Time Setup

If this is your first time building:

```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/native_assets/android

# 1. Make gradlew executable
chmod +x gradlew

# 2. Download dependencies (optional, happens automatically)
./gradlew --refresh-dependencies

# 3. Build
./gradlew buildWatcherApk
```

---

## Gradle Tasks Explained

### buildWatcherApk
- **What:** Builds instrumentation APK and copies to `build/libs/`
- **Use:** For building the native watcher
- **Output:** `build/libs/native_watcher.apk`

```bash
./gradlew buildWatcherApk
```

### buildWatcherJar (Legacy Alias)
- **What:** Calls `buildWatcherApk` (for backward compatibility)
- **Use:** If old scripts use this name
- **Output:** Same as `buildWatcherApk`

```bash
./gradlew buildWatcherJar
```

### assembleDebugAndroidTest
- **What:** Standard Android task to build test APK
- **Use:** Direct Android build (no copying)
- **Output:** `build/outputs/apk/androidTest/debug/...apk`

```bash
./gradlew assembleDebugAndroidTest
```

### clean
- **What:** Removes all build artifacts
- **Use:** Before rebuilding to ensure fresh build

```bash
./gradlew clean
```

---

## Troubleshooting

### Problem: "gradlew: command not found"

**Solution:**
```bash
chmod +x gradlew
./gradlew buildWatcherApk
```

### Problem: "SDK location not found"

**Solution:** Create `local.properties`:
```bash
echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties
```

### Problem: "Build failed with compilation error"

**Solution:** Check Java version:
```bash
java -version
# Should be 11 or higher

# If not, install:
brew install openjdk@11
```

### Problem: "APK not found after build"

**Check build output:**
```bash
ls -l build/outputs/apk/androidTest/debug/
ls -l build/libs/
```

**Rebuild:**
```bash
./gradlew clean buildWatcherApk
```

---

## Verify Build

After building, verify the APK:

```bash
# Check file exists
ls -lh build/libs/native_watcher.apk

# Check file size (should be ~100KB - 1MB)
du -h build/libs/native_watcher.apk

# Check it's a valid APK
file build/libs/native_watcher.apk
# Should show: "Android application package file"
```

---

## When to Rebuild

Rebuild the APK when you:

1. ✅ **Modify NativeWatcher.java** - New dialog handling logic
2. ✅ **Update dependencies** - New UI Automator version
3. ✅ **Change configuration** - New config options
4. ✅ **First time setup** - Initial build
5. ✅ **After pulling latest code** - Ensure you have latest version

---

## Build from Different Locations

### From project root:
```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot
./native_assets/android/gradlew -p native_assets/android buildWatcherApk
```

### From anywhere:
```bash
cd /path/to/flutter_test_pilot/native_assets/android
./gradlew buildWatcherApk
```

---

## CI/CD Integration

### GitHub Actions

```yaml
- name: Build Native Watcher
  run: |
    cd native_assets/android
    chmod +x gradlew
    ./gradlew buildWatcherApk
    
- name: Upload APK
  uses: actions/upload-artifact@v3
  with:
    name: native-watcher
    path: native_assets/android/build/libs/native_watcher.apk
```

### Jenkins

```groovy
stage('Build Native Watcher') {
    steps {
        dir('native_assets/android') {
            sh 'chmod +x gradlew'
            sh './gradlew buildWatcherApk'
        }
    }
}
```

---

## Quick Reference

| Command | Description | Output |
|---------|-------------|--------|
| `./build_watcher.sh` | Build with script | `build/libs/native_watcher.apk` |
| `./gradlew buildWatcherApk` | Build APK | `build/libs/native_watcher.apk` |
| `./gradlew buildWatcherJar` | Legacy build | `build/libs/native_watcher.apk` |
| `./gradlew clean` | Clean build | Removes all artifacts |
| `./gradlew --refresh-dependencies` | Update deps | Downloads latest deps |

---

## Success Indicators

After a successful build, you should see:

```
BUILD SUCCESSFUL in 15s
5 actionable tasks: 5 executed

✅ Watcher APK built: .../build/libs/native_watcher.apk
```

And the file should exist:
```bash
$ ls -lh build/libs/native_watcher.apk
-rw-r--r--  1 user  staff   450K Jan 21 10:30 build/libs/native_watcher.apk
```

---

## What's Next?

After building, you can:

1. ✅ **Use in tests** - APK is automatically detected
2. ✅ **Configure behavior** - Use `handler.configureWatcher()`
3. ✅ **Run integration tests** - With full native support

See the example folder for usage examples!

---

**Happy Building! 🚀**
