# 🚀 How to Use Flutter Test Pilot in Your Real Project

## Overview

This guide shows you **exactly** how to integrate and use all Phase 2 & 3 features in your actual Flutter project.

---

## 📋 Prerequisites

```bash
# 1. Install Android SDK (if not already installed)
# macOS:
brew install --cask android-platform-tools

# Or set ANDROID_HOME
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 2. Verify ADB is working
adb version

# 3. Connect a device or start emulator
adb devices
```

---

## 🔧 Setup in Your Project

### Step 1: Add flutter_test_pilot to your project

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test_pilot:
    path: ../flutter_test_pilot # Or from pub.dev when published

  integration_test:
  flutter_test: sdk
  glob: ^2.1.2
```

```bash
flutter pub get
```

---

## 📝 Real-World Example: Testing Your App with Native Support

### Example 1: Simple Integration Test with Native Handling

Create: `integration_test/login_flow_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login flow with native permissions', (tester) async {
    // Start your app
    app.main();
    await tester.pumpAndSettle();

    // Find login fields
    final emailField = find.byKey(Key('email_field'));
    final passwordField = find.byKey(Key('password_field'));
    final loginButton = find.byKey(Key('login_button'));

    // Enter credentials
    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'password123');
    await tester.pumpAndSettle();

    // Tap login
    await tester.tap(loginButton);
    await tester.pumpAndSettle(Duration(seconds: 3));

    // Verify success
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

---

### Example 2: Run Test with CLI (Using Native Features)

```bash
# Run integration test with native support
cd iltc-services/flutter_test_pilot

# Basic run
flutter test integration_test/login_flow_test.dart

# With native features (after implementing CLI integration)
dart run bin/flutter_test_pilot.dart run \
  integration_test/login_flow_test.dart \
  --app-id=com.example.yourapp \
  --native-watcher \
  --pre-grant-permissions=all \
  --disable-animations \
  --retry=2 \
  --screenshot
```

---

### Example 3: Programmatic Usage with All Features

Create: `test_runner/advanced_test_runner.dart`

```dart
import 'dart:io';
import 'package:flutter_test_pilot/native/adb_commander.dart';
import 'package:flutter_test_pilot/native/native_handler.dart';
import 'package:flutter_test_pilot/executor/retry_handler.dart';
import 'package:flutter_test_pilot/discovery/test_finder.dart';
import 'package:flutter_test_pilot/reporting/screenshot_capturer.dart';

Future<void> main() async {
  print('🚀 Running integration tests with full automation\n');

  // 1. Check environment
  final adb = AdbCommander();
  final devices = await adb.getDevices();

  if (devices.isEmpty) {
    print('❌ No devices connected. Connect a device first.');
    exit(1);
  }

  final deviceId = devices.first;
  print('📱 Using device: $deviceId\n');

  // 2. Setup native handler
  final handler = NativeHandler();
  final options = NativeOptions(
    packageName: 'com.example.yourapp',  // Your app package
    permissionMode: PermissionMode.all,
    enableWatcher: true,
    disableAnimations: true,
  );

  print('🔧 Setting up native features...');
  await handler.setupDevice(deviceId, options);
  print('✅ Device configured\n');

  // 3. Pre-grant permissions
  print('📋 Granting permissions...');
  await handler.grantPermissions(deviceId, options);
  print('✅ Permissions granted\n');

  // 4. Start dialog watcher
  print('🤖 Starting dialog watcher...');
  Process? watcherProcess;
  if (options.enableWatcher) {
    watcherProcess = await handler.startWatcher(deviceId, options);
    print('✅ Watcher running\n');
  }

  // 5. Discover and run tests
  final finder = TestFinder();
  final tests = await finder.findTests(
    patterns: ['integration_test/**/*_test.dart'],
  );

  print('🔍 Found ${tests.length} test(s)\n');

  // 6. Setup retry handler
  final retryHandler = RetryHandler(maxRetries: 2);
  final screenshotCapturer = ScreenshotCapturer(adb);

  // 7. Run each test with retry and screenshot on failure
  for (final testFile in tests) {
    print('🧪 Running: $testFile');

    final result = await retryHandler.runWithRetry(
      testPath: testFile,
      deviceId: deviceId,
      testRunner: () async {
        // Run actual flutter test
        final testResult = await Process.run(
          'flutter',
          ['test', testFile, '-d', deviceId],
        );

        final passed = testResult.exitCode == 0;

        return TestResult(
          testPath: testFile,
          testHash: 'hash_$testFile',
          passed: passed,
          duration: Duration(seconds: 30),
          timestamp: DateTime.now(),
          deviceId: deviceId,
          errorMessage: passed ? null : testResult.stderr.toString(),
        );
      },
      onRetry: (attempt, max, delay) {
        print('   ⏳ Retry $attempt/$max after ${delay.inSeconds}s...');
      },
    );

    if (result.passed) {
      print('   ✅ PASSED\n');
    } else {
      print('   ❌ FAILED: ${result.errorMessage}');

      // Capture screenshot on failure
      print('   📸 Capturing screenshot...');
      await screenshotCapturer.captureOnFailure(
        deviceId,
        testFile,
        result.errorMessage,
      );
      print('   ✅ Screenshot saved\n');
    }
  }

  // 8. Cleanup
  print('🧹 Cleaning up...');

  if (watcherProcess != null) {
    final stats = await handler.stopWatcher(watcherProcess, deviceId);
    print('   Watcher stats: ${stats.dialogsHandled} dialogs dismissed');
  }

  await handler.cleanup(deviceId, options);
  print('✅ Cleanup complete\n');
}
```

Run this:

```bash
dart run test_runner/advanced_test_runner.dart
```

---

## 🎯 Real-World Scenarios

### Scenario 1: Testing Camera Permission Flow

```dart
// integration_test/camera_permission_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Camera access with pre-granted permission', (tester) async {
    // Permission already granted by NativeHandler
    // No permission dialog will appear!

    await tester.tap(find.byKey(Key('open_camera_button')));
    await tester.pumpAndSettle();

    // Camera should open immediately
    expect(find.byKey(Key('camera_preview')), findsOneWidget);
  });
}
```

Run with permissions:

```bash
dart run bin/flutter_test_pilot.dart run \
  integration_test/camera_permission_test.dart \
  --app-id=com.example.yourapp \
  --pre-grant-permissions=custom \
  --custom-permissions=CAMERA,RECORD_AUDIO
```

---

### Scenario 2: Testing with Google Sign-In (Dialog Watcher)

```dart
testWidgets('Google Sign-In flow', (tester) async {
  await tester.tap(find.text('Sign in with Google'));
  await tester.pumpAndSettle();

  // DialogWatcher automatically dismisses Google Credential Picker!
  // No manual intervention needed

  // Continue with your test
  await tester.pump(Duration(seconds: 2));
  expect(find.text('Welcome'), findsOneWidget);
});
```

Run with watcher:

```bash
dart run bin/flutter_test_pilot.dart run \
  integration_test/google_signin_test.dart \
  --app-id=com.example.yourapp \
  --native-watcher
```

---

### Scenario 3: Parallel Testing on Multiple Devices

```dart
// test_runner/parallel_test_runner.dart
import 'package:flutter_test_pilot/executor/parallel_executor.dart';
import 'package:flutter_test_pilot/native/adb_commander.dart';

Future<void> main() async {
  final adb = AdbCommander();
  final devices = await adb.getDevices();

  if (devices.length < 2) {
    print('Need at least 2 devices for parallel testing');
    return;
  }

  final executor = ParallelExecutor(maxConcurrency: devices.length);

  final tests = [
    'integration_test/login_test.dart',
    'integration_test/signup_test.dart',
    'integration_test/profile_test.dart',
    'integration_test/settings_test.dart',
  ];

  print('Running ${tests.length} tests on ${devices.length} devices...\n');

  final results = await executor.runParallel(
    testFiles: tests,
    deviceIds: devices,
    testRunner: (testFile, deviceId) async {
      final result = await Process.run(
        'flutter',
        ['test', testFile, '-d', deviceId],
      );

      return TestResult(
        testPath: testFile,
        testHash: 'hash',
        passed: result.exitCode == 0,
        duration: Duration(seconds: 30),
        timestamp: DateTime.now(),
        deviceId: deviceId,
      );
    },
  );

  print('\n✅ Completed ${results.length} tests');
  print('   Passed: ${results.where((r) => r.passed).length}');
  print('   Failed: ${results.where((r) => !r.passed).length}');
}
```

---

## 🎬 Complete CI/CD Integration Example

```yaml
# .github/workflows/integration_tests.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Setup Android Emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 30
          arch: x86_64
          script: |
            # Run tests with native support
            cd iltc-services/flutter_test_pilot
            dart run bin/flutter_test_pilot.dart run \
              integration_test/ \
              --app-id=com.example.yourapp \
              --native-watcher \
              --pre-grant-permissions=all \
              --disable-animations \
              --retry=2 \
              --screenshot \
              --parallel \
              --concurrency=2

      - name: Upload Test Reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: test_reports/
```

---

## 📊 Expected Output

When you run tests with all features enabled:

```
🚀 Flutter Test Pilot - Running Integration Tests

📱 Device: emulator-5554 (Pixel 4, API 30)
🔧 Configuring device...
   ✅ Animations disabled

📋 Granting permissions...
   ✅ CAMERA - granted
   ✅ ACCESS_FINE_LOCATION - granted
   ✅ WRITE_EXTERNAL_STORAGE - granted

🤖 Starting dialog watcher...
   ✅ Watcher running (PID 12345)

🧪 Running 5 tests...

[Test 1/5] integration_test/login_test.dart
   🧪 Attempt 1/3...
   ✅ PASSED (12.3s)

[Test 2/5] integration_test/camera_test.dart
   🧪 Attempt 1/3...
   ✅ PASSED (8.5s)

[Test 3/5] integration_test/payment_test.dart
   🧪 Attempt 1/3...
   ❌ FAILED (network timeout)
   ⏳ Retrying after 5s...
   🧪 Attempt 2/3...
   ✅ PASSED (9.2s)

[Test 4/5] integration_test/profile_test.dart
   ✅ PASSED (cached, 0.3s)

[Test 5/5] integration_test/settings_test.dart
   🧪 Attempt 1/3...
   ❌ FAILED (assertion error)
   📸 Screenshot captured

📊 Test Results:
   Total: 5
   Passed: 4
   Failed: 1
   Duration: 45.2s

🤖 Dialog Watcher Stats:
   Dialogs handled: 3
   - Google Credential Picker: 2
   - System alert: 1

📸 Screenshots:
   - settings_test_failure_1705920123.png

🧹 Cleanup complete
```

---

## 🎯 Tips for Real Projects

### 1. **Always Use Keys** in Your Widgets

```dart
// Bad
TextField()

// Good
TextField(key: Key('email_field'))
```

### 2. **Structure Your Integration Tests**

```
integration_test/
├── flows/
│   ├── login_flow_test.dart
│   ├── signup_flow_test.dart
│   └── checkout_flow_test.dart
├── screens/
│   ├── home_screen_test.dart
│   └── profile_screen_test.dart
└── helpers/
    └── test_helpers.dart
```

### 3. **Use Native Features Selectively**

- Use `--native-watcher` for OAuth/Google Sign-In tests
- Use `--pre-grant-permissions` for camera/location tests
- Use `--disable-animations` for faster test execution
- Use `--retry` for flaky network-dependent tests

### 4. **Monitor Your Test Performance**

```bash
# Run with timing
time dart run bin/flutter_test_pilot.dart run integration_test/ --verbose
```

---

## 🐛 Troubleshooting

### Issue: "ADB not found"

```bash
# macOS
brew install --cask android-platform-tools

# Or manually
export PATH=$PATH:~/Library/Android/sdk/platform-tools
```

### Issue: "Permission denied" when granting permissions

```bash
# Check device permissions
adb shell pm list permissions -d -g
```

### Issue: "Dialog watcher not working"

```bash
# Build the watcher JAR
cd native_assets/android
gradle wrapper
./gradlew buildWatcherJar
```

### Issue: "Test hangs on native dialog"

```bash
# Enable watcher and verify
dart run bin/flutter_test_pilot.dart run test.dart \
  --native-watcher --verbose
```

---

## ✅ You're Ready!

You now know how to:

- ✅ Use native permission handling in real tests
- ✅ Auto-dismiss native dialogs
- ✅ Implement retry logic for flaky tests
- ✅ Run tests in parallel for 3x+ speedup
- ✅ Capture screenshots on failures
- ✅ Integrate with CI/CD pipelines

**Next:** Try running your first test with native support! 🚀
