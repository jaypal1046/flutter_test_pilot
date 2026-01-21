# 🧪 How to Test the Test-Driven Native Watcher

## 🎯 What You'll Test

This demo tests the **test-driven native watcher** that allows your Flutter tests to control how native dialogs are handled (allow/deny/ignore).

## 📋 Prerequisites

### 1. Build the Native Watcher APK

```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/native_assets/android

# macOS/Linux
./build_watcher.sh

# Windows
build_watcher.bat
```

**Expected output:**
```
✅ SUCCESS! Native Watcher APK built successfully!
📦 Location: build/libs/native_watcher.apk
```

### 2. Connect Android Device/Emulator

```bash
# Check connected devices
adb devices

# Expected output:
# List of devices attached
# emulator-5554   device
```

### 3. Install Dependencies

```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/example

flutter pub get
```

---

## 🚀 Run the Tests

### Option 1: Run All Tests (Recommended)

```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/example

flutter test integration_test/test_driven_watcher_example.dart
```

### Option 2: Run with Device Selection

```bash
# List devices
flutter devices

# Run on specific device
flutter test integration_test/test_driven_watcher_example.dart -d <device-id>
```

### Option 3: Run with Integration Test Driver

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/test_driven_watcher_example.dart
```

---

## 📊 What the Tests Do

### ✅ TEST 1: Allow All Permissions (Grant Flow)
- **Configuration:** `DialogAction.allow`
- **Tests:** Camera and storage permissions are auto-granted
- **Verifies:** Grant flow works correctly

### ❌ TEST 2: Deny All Permissions (Denial Flow)
- **Configuration:** `DialogAction.deny`
- **Tests:** Permissions are auto-denied
- **Verifies:** Denial flow works correctly

### 📍 TEST 3: Location with Precision
- **Configuration:** `LocationPrecision.precise`
- **Tests:** Location permission with precise selection
- **Verifies:** Precision selection works

### 🎭 TEST 4: Mixed Configuration
- **Configuration:** Allow permissions, deny notifications
- **Tests:** Different behaviors for different dialog types
- **Verifies:** Selective handling works

### 🔄 TEST 5: Configuration Isolation
- **Configuration:** Changes between tests
- **Tests:** Each test has independent configuration
- **Verifies:** No interference between tests

---

## 📺 Expected Test Output

```
======================================================================
🚀 Setting up test-driven native watcher demo
======================================================================
📱 Using device: emulator-5554
🔍 Device capabilities:
   • UI Automator: ✅
   • Permission Granting: ✅
   • API Level: 33

----------------------------------------------------------------------
✅ TEST 1: Testing permission GRANT flow
----------------------------------------------------------------------

📝 Step 1: Configuring watcher to ALLOW permissions
   ✅ Configuration set: ALLOW all

🤖 Step 2: Starting native watcher
  ✅ Watcher APK found: .../native_watcher.apk
  📤 Installing watcher APK...
  ✅ Watcher APK installed
  🚀 Starting watcher process...
  ✅ Watcher started (PID: 12345)
   ✅ Watcher started

🚀 Step 3: Launching test app
   ✅ App launched
   ✅ Home screen verified

🔍 Step 4: Testing permissions page
   ✅ Navigated to permissions page

📷 Step 5: Requesting camera permission
   ✅ Camera permission requested
   ℹ️  Native watcher should have granted it automatically

💾 Step 6: Requesting storage permission
   ✅ Storage permission requested

🛑 Step 7: Stopping watcher and collecting stats
   📊 Watcher Statistics:
      • Dialogs detected: 2
      • Dialogs dismissed: 2

✅ TEST 1 COMPLETE: Permission grant flow tested successfully!

[... continues for all 5 tests ...]

======================================================================
🎉 ALL TESTS COMPLETED!
======================================================================

📊 Test Summary:
   ✅ TEST 1: Permission grant flow
   ✅ TEST 2: Permission denial flow
   ✅ TEST 3: Location precision selection
   ✅ TEST 4: Mixed configuration
   ✅ TEST 5: Configuration isolation

🎯 Key Features Tested:
   • Test-driven configuration
   • Dynamic allow/deny behavior
   • Location precision selection
   • Configuration isolation between tests
   • Statistics collection

🚀 The test-driven native watcher is working correctly!
======================================================================
```

---

## 🐛 Troubleshooting

### Problem: "APK not found"

**Solution:**
```bash
cd native_assets/android
./build_watcher.sh  # Build the APK first
```

### Problem: "No Android device connected"

**Solution:**
```bash
# Start emulator
emulator -avd <your_avd_name>

# OR connect physical device via USB
# Then verify:
adb devices
```

### Problem: "UI Automator not supported"

**Check device API level:**
```bash
adb shell getprop ro.build.version.sdk

# Should be 18 or higher
```

### Problem: Tests hang or timeout

**Check watcher logs:**
```bash
adb logcat -s TestPilotWatcher

# You should see:
# 🤖 Native watcher started (TEST-DRIVEN MODE)
# 📝 Configuration loaded from test:
#    Permissions: allow
```

### Problem: "Configuration not applied"

**Verify config file:**
```bash
adb shell cat /sdcard/flutter_test_pilot_watcher_config.json

# Should show JSON like:
# {"permissions":"allow","location":"precise",...}
```

**Clear and retry:**
```bash
adb shell rm /sdcard/flutter_test_pilot_watcher_config.json
# Run test again
```

---

## 📝 Manual Testing (Without Integration Tests)

If you want to manually test the app:

### 1. Run the app
```bash
cd example
flutter run
```

### 2. You'll see three test options:
- **Test Permissions** - Request camera, storage, all permissions
- **Test Location** - Request location with precision
- **Test Notifications** - Request notification permission

### 3. Tap through each option to test the UI

**Note:** Manual testing won't demonstrate the native watcher since system dialogs require actual permissions. The integration tests are needed for full testing.

---

## 🎬 Demo Video Flow

If you want to record a demo:

1. **Start screen recording:**
   ```bash
   adb shell screenrecord /sdcard/test_demo.mp4
   ```

2. **Run the test:**
   ```bash
   flutter test integration_test/test_driven_watcher_example.dart
   ```

3. **Stop recording:**
   ```bash
   # Press Ctrl+C after test completes
   
   # Pull video
   adb pull /sdcard/test_demo.mp4 .
   ```

---

## 📚 What's Being Tested?

### Architecture
```
Your Test (Dart)
    ↓
    Writes JSON config to device
    ↓
Native Watcher APK (Java)
    ↓
    Reads config every 5 seconds
    ↓
    Acts on native dialogs based on config
```

### Configuration Flow
```
TEST 1: allow → Watcher grants permissions
TEST 2: deny → Watcher denies permissions
TEST 3: precise → Watcher selects precise location
TEST 4: mixed → Watcher handles each type differently
TEST 5: Changes between tests → Watcher adapts
```

---

## ✅ Success Indicators

You'll know it's working when you see:

1. ✅ **APK builds successfully** - `build/libs/native_watcher.apk` exists
2. ✅ **Watcher starts** - "Watcher started (PID: xxxxx)" in output
3. ✅ **Configuration loaded** - "Configuration loaded from test" in logs
4. ✅ **Tests pass** - All 5 tests show ✅
5. ✅ **Statistics reported** - "Dialogs detected: X, dismissed: Y"

---

## 🎯 Next Steps

After confirming the tests work:

1. **Use in your own tests:**
   ```dart
   await handler.configureWatcher(
     deviceId: deviceId,
     permissionAction: DialogAction.allow,
   );
   ```

2. **Customize configuration for your app's needs**

3. **Add your own test scenarios**

4. **Integrate into CI/CD pipeline**

---

**Happy Testing! 🚀**
