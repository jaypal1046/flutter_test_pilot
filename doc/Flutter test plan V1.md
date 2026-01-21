V1:
# 🚀 Flutter Test Pilot CLI - Complete Implementation Plan

**Project:** Flutter Test Pilot Custom CLI Test Runner  
**Timeline:** 4-6 weeks (phased approach)  
**Goal:** Full control over integration test execution with native action handling  
**Status:** Planning Phase  
**Last Updated:** January 19, 2026

---

## 📋 **Executive Summary**

Create a custom CLI command `flutter_test_pilot run` that provides complete control over Flutter integration test execution, including:

- ✅ **Native Layer Control** - Pre-grant permissions, dismiss dialogs, control device settings
- ✅ **Real Device Execution** - Uses `flutter drive` instead of headless `flutter test`
- ✅ **Parallel UI Automator** - Background watcher process for native dialog handling
- ✅ **Advanced Retry Logic** - Smart failure recovery with exponential backoff
- ✅ **Rich Reporting** - HTML, JSON, JUnit, Markdown reports
- ✅ **CI/CD Integration** - GitHub Actions, Jenkins, GitLab CI ready

---

## 🎯 **Why We Need This**

### **Current Problem with `flutter test`:**

```bash
flutter test integration_test/login_test.dart
```

**Issues:**

- ❌ Runs in **headless mode** (no real device)
- ❌ **No ADB access** (can't control device)
- ❌ **Can't handle native dialogs** (Google Credential Picker hangs tests)
- ❌ **No permission granting** (runtime dialogs interrupt tests)
- ❌ **Limited control** over test execution lifecycle

### **Solution with `flutter_test_pilot run`:**

```bash
flutter_test_pilot run integration_test/login_test.dart \
  --device=emulator-5554 \
  --pre-grant-permissions=all \
  --native-watcher=enabled \
  --retry-failures=3 \
  --report=html,json,junit
```

**Benefits:**

- ✅ Runs on **real device** via `flutter drive`
- ✅ **Full ADB access** for device control
- ✅ **Native dialog handling** via UI Automator
- ✅ **Pre-grant permissions** (no runtime interruptions)
- ✅ **Complete control** over execution, retries, reporting

---

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────┐
│  flutter_test_pilot run integration_test/login_test.dart│
│  (Custom CLI - runs on macOS)                          │
└──────────────────┬──────────────────────────────────────┘
                   │
    ┌──────────────┴──────────────┐
    │                             │
    ▼                             ▼
┌─────────────────┐    ┌─────────────────────────┐
│  Process 1:     │    │  Process 2:             │
│  ADB Commands   │    │  flutter drive          │
│  (Native Layer) │    │  (Flutter Test)         │
└─────────────────┘    └─────────────────────────┘
    │                             │
    │                             │
    └──────────┬──────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Android Device      │
    │  (emulator-5554)     │
    └──────────────────────┘
```

### **Key Insight:**

Your CLI spawns **TWO parallel processes**:

1. **Process 1 (Native Handler):** Runs UI Automator watcher to monitor and dismiss native dialogs
2. **Process 2 (Test Executor):** Runs `flutter drive` to execute your integration test

**Both processes** access the **same real device** simultaneously!

---

## 📦 **Package Structure**

```
flutter_test_pilot/
├── bin/
│   └── flutter_test_pilot.dart          # CLI entry point (executable)
│
├── lib/
│   ├── cli/
│   │   ├── command_runner.dart          # Main command handler
│   │   ├── commands/
│   │   │   ├── run_command.dart         # 'run' - Execute tests
│   │   │   ├── doctor_command.dart      # 'doctor' - Check environment
│   │   │   ├── config_command.dart      # 'config' - Manage settings
│   │   │   ├── init_command.dart        # 'init' - Bootstrap project
│   │   │   └── devices_command.dart     # 'devices' - List devices
│   │   └── args/
│   │       └── run_args.dart            # Argument definitions
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── test_pilot_config.dart   # Configuration model
│   │   │   └── config_loader.dart       # Load .testpilot.yaml
│   │   ├── logger/
│   │   │   ├── console_logger.dart      # Pretty console output
│   │   │   └── file_logger.dart         # Log to file
│   │   └── models/
│   │       ├── test_result.dart         # Test execution result
│   │       ├── device_info.dart         # Device metadata
│   │       └── native_event.dart        # Native dialog events
│   │
│   ├── device/
│   │   ├── device_manager.dart          # Device discovery/management
│   │   ├── android_device.dart          # Android-specific logic
│   │   ├── ios_device.dart              # iOS-specific logic
│   │   └── device_setup.dart            # Pre-test device setup
│   │
│   ├── native/
│   │   ├── native_handler.dart          # Native action orchestrator
│   │   ├── permission_granter.dart      # Grant permissions via ADB
│   │   ├── dialog_watcher.dart          # UI Automator integration
│   │   ├── adb_commander.dart           # ADB command wrapper
│   │   └── ui_automator/
│   │       ├── watcher_builder.dart     # Generate UI Automator code
│   │       ├── watcher_compiler.dart    # Compile JAR
│   │       └── watcher_deployer.dart    # Deploy to device
│   │
│   ├── executor/
│   │   ├── test_executor.dart           # Main test execution logic
│   │   ├── flutter_driver_runner.dart   # Wrap flutter drive
│   │   ├── parallel_executor.dart       # Run tests in parallel
│   │   ├── retry_handler.dart           # Retry failed tests
│   │   └── process_manager.dart         # Manage child processes
│   │
│   ├── discovery/
│   │   ├── test_finder.dart             # Find test files
│   │   ├── test_parser.dart             # Parse test metadata
│   │   └── tag_manager.dart             # Handle test tags
│   │
│   ├── reporting/
│   │   ├── report_generator.dart        # Multi-format reports
│   │   ├── reporters/
│   │   │   ├── html_reporter.dart       # HTML report
│   │   │   ├── json_reporter.dart       # JSON report
│   │   │   ├── junit_reporter.dart      # JUnit XML
│   │   │   └── markdown_reporter.dart   # Markdown summary
│   │   ├── screenshot_capturer.dart     # Capture on failure
│   │   └── video_recorder.dart          # Record test execution
│   │
│   ├── bootstrap/
│   │   ├── test_bootstrap_injector.dart # Inject setup code
│   │   └── driver_generator.dart        # Generate test_driver/
│   │
│   └── utils/
│       ├── file_utils.dart              # File operations
│       ├── process_utils.dart           # Process helpers
│       └── validation_utils.dart        # Input validation
│
├── native_assets/
│   ├── android/
│   │   ├── NativeWatcher.java           # UI Automator watcher
│   │   ├── build.gradle                 # Build UI Automator JAR
│   │   └── AndroidManifest.xml          # Manifest for watcher
│   └── ios/
│       └── NativeWatcher.swift          # XCUITest watcher (future)
│
├── templates/
│   ├── test_driver/
│   │   └── integration_test.dart        # Driver template
│   ├── config/
│   │   └── .testpilot.yaml              # Config template
│   └── test/
│       └── example_test.dart            # Example test
│
├── test/
│   └── ... (unit tests for CLI)
│
├── pubspec.yaml
├── CLI_IMPLEMENTATION_PLAN.md           # This file
└── README.md
```

---

## 📅 **Implementation Timeline - 4 Phases**

---

## **Phase 1: Foundation (Week 1-2)**

**Goal:** Basic CLI with device management and simple test execution

### **Milestone 1.1: CLI Bootstrap (Days 1-2)**

**Tasks:**

- [ ] Create package structure
- [ ] Setup `bin/flutter_test_pilot.dart` as executable
- [ ] Implement `CommandRunner` with `args` package
- [ ] Add basic commands: `--help`, `--version`
- [ ] Create logger system (console + file)

**Code Example:**

```dart
// bin/flutter_test_pilot.dart
import 'package:args/command_runner.dart';
import '../lib/cli/commands/run_command.dart';

void main(List<String> args) async {
  final runner = CommandRunner(
    'flutter_test_pilot',
    'Advanced Flutter integration testing CLI',
  )
    ..addCommand(RunCommand())
    ..addCommand(DoctorCommand())
    ..addCommand(DevicesCommand());

  await runner.run(args);
}
```

**Deliverable:**

```bash
flutter_test_pilot --help
flutter_test_pilot --version
# Output: flutter_test_pilot v0.1.0
```

---

### **Milestone 1.2: Device Manager (Days 3-4)**

**Tasks:**

- [ ] Implement device detection (`adb devices`)
- [ ] Create device info models (OS version, API level)
- [ ] Build device selector logic
- [ ] Add device validation

**Code Example:**

```dart
// lib/device/device_manager.dart
class DeviceManager {
  Future<List<DeviceInfo>> getDevices() async {
    final result = await Process.run('adb', ['devices', '-l']);
    // Parse and return device list
  }
}
```

**Deliverable:**

```bash
flutter_test_pilot devices

# Output:
# 📱 Available Devices:
#   1. emulator-5554 (Android 13, API 33)
#   2. emulator-5556 (Android 12, API 31)
```

---

### **Milestone 1.3: Basic Test Runner (Days 5-7)**

**Tasks:**

- [ ] Implement `flutter drive` wrapper
- [ ] Create test driver generator
- [ ] Add basic test execution
- [ ] Handle stdout/stderr streaming

**Code Example:**

```dart
// lib/executor/test_executor.dart
class TestExecutor {
  Future<void> runTest(String testFile, String device) async {
    final process = await Process.start('flutter', [
      'drive',
      '--driver=test_driver/integration_test.dart',
      '--target=$testFile',
      '-d', device,
    ]);

    // Stream output
    process.stdout.transform(utf8.decoder).listen(print);
    process.stderr.transform(utf8.decoder).listen(print);

    final exitCode = await process.exitCode;
    // Handle result
  }
}
```

**Deliverable:**

```bash
flutter_test_pilot run integration_test/login_test.dart

# Output:
# 🚀 Flutter Test Pilot v0.1.0
# 📱 Running on: emulator-5554
# 🧪 Executing: integration_test/login_test.dart
# ✅ Test passed (12.3s)
```

---

### **Milestone 1.4: Doctor Command (Days 8-9)**

**Tasks:**

- [ ] Implement environment checker
- [ ] Verify Flutter installation
- [ ] Check ADB/device connectivity
- [ ] Validate Java (for UI Automator)

**Deliverable:**

```bash
flutter_test_pilot doctor

# Output:
# ✅ Flutter SDK: 3.x.x
# ✅ ADB: 34.0.5
# ✅ Devices: 1 connected
# ✅ Java: 17.0.9
# ✅ Android SDK: API 33
```

---

### **Milestone 1.5: Configuration System (Days 10-12)**

**Tasks:**

- [ ] Implement `.testpilot.yaml` parser
- [ ] Create config models
- [ ] Add config validation
- [ ] Support CLI arg overrides

**Config File:**

```yaml
# .testpilot.yaml
version: 1.0

device:
  auto_select: true
  platform: android

test:
  timeout: 5m
  retry_failures: 3

native:
  pre_grant_permissions: true
  watcher_enabled: true

reporting:
  formats: [html, json, junit]
  output_dir: ./test_reports
  screenshot_on_failure: true
```

---

## **Phase 2: Native Action Handling (Week 3)** 🔥

**Goal:** Full native layer control with permission granting and dialog handling

### **Milestone 2.1: ADB Command Wrapper (Days 13-14)**

**Tasks:**

- [ ] Create `AdbCommander` class
- [ ] Implement common ADB commands
- [ ] Add error handling and retries
- [ ] Support multi-device selection

**Code Example:**

```dart
// lib/native/adb_commander.dart
class AdbCommander {
  Future<void> grantPermission(
    String device,
    String permission,
  ) async {
    await Process.run('adb', [
      '-s', device,
      'shell', 'pm', 'grant',
      'com.your.app',
      'android.permission.$permission',
    ]);
  }

  Future<void> clearAppData(String device, String package) async {
    await Process.run('adb', ['-s', device, 'shell', 'pm', 'clear', package]);
  }

  Future<void> pressBack(String device) async {
    await Process.run('adb', ['-s', device, 'shell', 'input', 'keyevent', '4']);
  }

  Future<void> disableAnimations(String device) async {
    final settings = [
      'window_animation_scale',
      'transition_animation_scale',
      'animator_duration_scale',
    ];
    for (final setting in settings) {
      await Process.run('adb', [
        '-s', device,
        'shell', 'settings', 'put', 'global', setting, '0',
      ]);
    }
  }
}
```

---

### **Milestone 2.2: Permission Granter (Days 15-16)**

**Tasks:**

- [ ] Implement pre-grant permission service
- [ ] Support batch granting
- [ ] Add permission validation
- [ ] Handle Android/iOS differences

**Code Example:**

```dart
// lib/native/permission_granter.dart
class PermissionGranter {
  static const commonPermissions = [
    'ACCESS_FINE_LOCATION',
    'ACCESS_COARSE_LOCATION',
    'CAMERA',
    'READ_EXTERNAL_STORAGE',
    'WRITE_EXTERNAL_STORAGE',
    'RECEIVE_SMS',
    'READ_SMS',
    'POST_NOTIFICATIONS',
  ];

  Future<void> grantAll(String device, String package) async {
    print('📋 Granting permissions for: $package');

    for (final permission in commonPermissions) {
      try {
        await _adb.grantPermission(device, permission);
        print('  ✅ Granted: $permission');
      } catch (e) {
        print('  ⚠️  Failed: $permission ($e)');
      }
    }
  }
}
```

**Deliverable:**

```bash
flutter_test_pilot run integration_test/login_test.dart \
  --pre-grant-permissions=all

# Output:
# 📱 Device setup...
# ✅ Granted: ACCESS_FINE_LOCATION
# ✅ Granted: CAMERA
# ✅ Granted: READ_EXTERNAL_STORAGE
# ✅ Granted: RECEIVE_SMS
# ✅ Granted: POST_NOTIFICATIONS
# 🧪 Running test...
```

---

### **Milestone 2.3: UI Automator Watcher (Days 17-19)** 🎯

**This is the KEY to native dialog handling!**

**Tasks:**

- [ ] Create Java UI Automator watcher code
- [ ] Implement dialog detection logic
- [ ] Add auto-dismiss actions
- [ ] Build JAR compilation pipeline
- [ ] Implement watcher deployer

**Native Watcher Code:**

```java
// native_assets/android/NativeWatcher.java
package com.testpilot.watcher;

import androidx.test.uiautomator.*;
import android.util.Log;

public class NativeWatcher extends UiAutomatorTestCase {
  private static final String TAG = "TestPilotWatcher";

  public void testWatchForDialogs() throws Exception {
    UiDevice device = getUiDevice();

    Log.d(TAG, "🤖 Native watcher started");

    while (true) {
      // 1. Watch for Google Credential Picker
      UiObject2 picker = device.findObject(
        By.res("com.google.android.gms:id/credential_picker")
      );

      if (picker != null) {
        Log.d(TAG, "🚨 Detected: Google Credential Picker");
        device.pressBack();
        Log.d(TAG, "✅ Dismissed via back button");
        Thread.sleep(500); // Stabilize
      }

      // 2. Watch for permission dialogs
      UiObject2 permDialog = device.findObject(
        By.text("Allow").pkg("com.google.android.permissioncontroller")
      );

      if (permDialog != null) {
        Log.d(TAG, "🚨 Detected: Permission Dialog");
        permDialog.click();
        Log.d(TAG, "✅ Granted permission");
        Thread.sleep(500);
      }

      // 3. Watch for "Just Once" / "While using the app" buttons
      UiObject2 justOnce = device.findObject(By.text("Just once"));
      if (justOnce != null) {
        justOnce.click();
        Log.d(TAG, "✅ Clicked: Just once");
        Thread.sleep(500);
      }

      // Check every 200ms
      Thread.sleep(200);
    }
  }
}
```

**Build Script:**

```gradle
// native_assets/android/build.gradle
apply plugin: 'java'

dependencies {
    implementation 'androidx.test.uiautomator:uiautomator:2.2.0'
    implementation 'junit:junit:4.13.2'
}

task buildWatcherJar(type: Jar) {
    from sourceSets.main.output
    archiveFileName = 'native_watcher.jar'
}
```

**Dart Integration:**

```dart
// lib/native/dialog_watcher.dart
class DialogWatcher {
  Future<Process> start(String device) async {
    // 1. Compile JAR (if not exists)
    await _compileWatcher();

    // 2. Push JAR to device
    await Process.run('adb', [
      '-s', device,
      'push',
      'native_assets/android/build/native_watcher.jar',
      '/sdcard/',
    ]);

    // 3. Start watcher process
    final process = await Process.start('adb', [
      '-s', device,
      'shell',
      'uiautomator', 'runtest', '/sdcard/native_watcher.jar',
      '-c', 'com.testpilot.watcher.NativeWatcher',
    ]);

    // 4. Stream logs
    process.stdout.transform(utf8.decoder).listen((line) {
      print('[Native] $line');
    });

    return process;
  }
}
```

---

### **Milestone 2.4: Native Handler Orchestrator (Days 20-21)**

**Tasks:**

- [ ] Integrate watcher with test executor
- [ ] Manage parallel processes
- [ ] Capture native events
- [ ] Add event logging

**Code Example:**

```dart
// lib/native/native_handler.dart
class NativeHandler {
  Future<void> runWithNativeSupport(
    String device,
    String testFile,
  ) async {
    Process? watcherProcess;

    try {
      // Step 1: Grant permissions
      await _permissionGranter.grantAll(device, 'com.your.app');

      // Step 2: Start native watcher
      print('🤖 Starting native watcher...');
      watcherProcess = await _dialogWatcher.start(device);

      // Wait for watcher to initialize
      await Future.delayed(Duration(seconds: 2));

      // Step 3: Run Flutter test
      print('🧪 Running test...');
      await _testExecutor.runTest(testFile, device);

    } finally {
      // Step 4: Stop watcher
      watcherProcess?.kill();
      print('🛑 Stopped native watcher');
    }
  }
}
```

**Deliverable:**

```bash
flutter_test_pilot run integration_test/login_test.dart \
  --native-watcher=enabled

# Output:
# 📱 Device: emulator-5554
# 📋 Granting permissions...
#   ✅ Granted 5 permissions
# 🤖 Starting native watcher (PID: 12345)
# 🧪 Running test...
# [Native] 🤖 Native watcher started
# [Test] 🧪 Initializing test...
# [Native] 🚨 Detected: Google Credential Picker at 10:23:15
# [Native] ✅ Dismissed via back button
# [Test] ✅ Login test passed (12.3s)
# 🛑 Stopped native watcher
# 📊 Native events: 1 dialog dismissed
```

---

## **Phase 3: Advanced Features (Week 4)**

**Goal:** Parallel execution, retry logic, and advanced reporting

### **Milestone 3.1: Test Discovery (Days 22-23)**

**Tasks:**

- [ ] Implement test file finder (glob patterns)
- [ ] Support test tags/metadata parsing
- [ ] Group tests by tags
- [ ] Add test filtering

**Deliverable:**

```bash
flutter_test_pilot run integration_test/ --tags=smoke

# Output:
# 🔍 Discovered 12 tests
# 🏷️  Filtered by tags: smoke
# ✅ 5 tests selected
```

---

### **Milestone 3.2: Retry Handler (Days 24-25)**

**Tasks:**

- [ ] Implement retry logic
- [ ] Support exponential backoff
- [ ] Track retry attempts
- [ ] Generate retry reports

**Code Example:**

```dart
// lib/executor/retry_handler.dart
class RetryHandler {
  Future<void> runWithRetry(
    String testFile,
    String device, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 5),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      attempt++;
      print('🧪 Attempt $attempt/$maxRetries');

      try {
        await _executor.runTest(testFile, device);
        print('✅ Test passed');
        return;
      } catch (e) {
        print('❌ Attempt $attempt failed: $e');

        if (attempt < maxRetries) {
          print('⏳ Waiting ${delay.inSeconds}s before retry...');
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
        }
      }
    }

    throw Exception('Test failed after $maxRetries attempts');
  }
}
```

**Deliverable:**

```bash
flutter_test_pilot run integration_test/flaky_test.dart \
  --retry-failures=3 \
  --retry-delay=5s

# Output:
# 🧪 Attempt 1/3: ❌ Failed (Network timeout)
# ⏳ Waiting 5s before retry...
# 🧪 Attempt 2/3: ❌ Failed (Native dialog)
# ⏳ Waiting 10s before retry...
# 🧪 Attempt 3/3: ✅ Passed
```

---

### **Milestone 3.3: Parallel Executor (Days 26-28)**

**Tasks:**

- [ ] Implement parallel test execution
- [ ] Manage multiple device connections
- [ ] Queue management
- [ ] Load balancing

**Deliverable:**

```bash
flutter_test_pilot run integration_test/ \
  --parallel=4 \
  --devices=emulator-5554,emulator-5556,emulator-5558,emulator-5560

# Output:
# 🚀 Running 12 tests on 4 devices
# [Device 1] ✅ login_test.dart (10s)
# [Device 2] ✅ signup_test.dart (15s)
# [Device 3] ❌ payment_test.dart (20s) - Retrying...
# [Device 4] ✅ profile_test.dart (8s)
# ...
# 📊 Summary: 11/12 passed (3m 45s)
```

---

### **Milestone 3.4: Screenshot & Video Capture (Days 29-30)**

**Tasks:**

- [ ] Implement screenshot on failure
- [ ] Add video recording support
- [ ] Integrate with ADB screencap/screenrecord
- [ ] Store artifacts in report dir

**Deliverable:**

```bash
flutter_test_pilot run integration_test/login_test.dart \
  --screenshot-on-failure \
  --video-recording

# Output:
# 🧪 Running test...
# ❌ Test failed at step 5
# 📸 Screenshot saved: ./test_reports/login_test_failure.png
# 🎥 Video saved: ./test_reports/login_test_recording.mp4
```

---

## **Phase 4: Reporting & CI/CD (Week 5-6)**

**Goal:** Production-ready reports, CI/CD integration, and polish

### **Milestone 4.1: Multi-Format Reports (Days 31-33)**

**Tasks:**

- [ ] Implement HTML reporter (with charts)
- [ ] Implement JSON reporter
- [ ] Implement JUnit XML reporter
- [ ] Implement Markdown reporter
- [ ] Add native event timeline

**Deliverable:**

```bash
flutter_test_pilot run integration_test/ \
  --report=html,json,junit

# Generates:
# ./test_reports/
#   ├── report.html       (Rich HTML with charts)
#   ├── report.json       (Machine-readable)
#   ├── junit.xml         (CI/CD compatible)
#   └── summary.md        (Markdown summary)
```

**HTML Report Features:**

- ✅ Test suite summary (pass/fail/skip counts)
- ✅ Native event timeline (when dialogs were dismissed)
- ✅ Performance metrics (test duration, device CPU/memory)
- ✅ Screenshots embedded
- ✅ Interactive charts
- ✅ Filterable test list

---

### **Milestone 4.2: CI/CD Integration (Days 34-36)**

**Tasks:**

- [ ] Add machine-readable output
- [ ] Implement exit codes
- [ ] Support CI environment detection
- [ ] Create GitHub Actions template
- [ ] Create Jenkins template

**GitHub Actions Template:**

```yaml
# .github/workflows/integration-tests.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.x"

      - name: Setup Android Emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 33
          script: echo "Emulator ready"

      - name: Install Flutter Test Pilot
        run: dart pub global activate flutter_test_pilot

      - name: Run Integration Tests
        run: |
          flutter_test_pilot run integration_test/ \
            --ci-mode \
            --no-color \
            --machine-output \
            --report=junit \
            --screenshot-on-failure \
            --pre-grant-all \
            --native-watcher=enabled

      - name: Publish Test Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: test_reports/junit.xml

      - name: Upload Artifacts
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-reports
          path: test_reports/
```

---

### **Milestone 4.3: Performance Profiling (Days 37-38)**

**Tasks:**

- [ ] Track test execution time
- [ ] Monitor device performance (CPU, memory)
- [ ] Generate performance reports
- [ ] Add performance thresholds

**Deliverable:**

```bash
flutter_test_pilot run integration_test/login_test.dart \
  --performance-profiling

# Output:
# 📊 Performance Metrics:
#   Test Duration: 12.3s
#   Device CPU: 45% avg, 78% peak
#   Device Memory: 512MB avg, 680MB peak
#   Native Dialog Overhead: 1.2s (9.8%)
#   Network Requests: 5 (2.4s total)
```

---

### **Milestone 4.4: Init Command & Templates (Days 39-40)**

**Tasks:**

- [ ] Implement `init` command
- [ ] Generate test_driver/ structure
- [ ] Create example tests
- [ ] Generate .testpilot.yaml

**Deliverable:**

```bash
flutter_test_pilot init

# Output:
# 🎉 Initializing Flutter Test Pilot...
# ✅ Created: test_driver/integration_test.dart
# ✅ Created: integration_test/example_test.dart
# ✅ Created: .testpilot.yaml
# ✅ Updated: pubspec.yaml
#
# 📝 Next steps:
#   1. Edit .testpilot.yaml to configure settings
#   2. Run: flutter_test_pilot run integration_test/example_test.dart
```

---

### **Milestone 4.5: Documentation & Polish (Days 41-42)**

**Tasks:**

- [ ] Write comprehensive README
- [ ] Create usage guide
- [ ] Add troubleshooting section
- [ ] Polish error messages
- [ ] Add progress indicators

---

## 📊 **Success Criteria**

### **Phase 1 Success:**

- ✅ CLI executable runs on macOS/Linux/Windows
- ✅ Can detect and select devices
- ✅ Can execute basic test with `flutter drive`
- ✅ Doctor command validates environment

### **Phase 2 Success (CRITICAL):**

- ✅ Can pre-grant all permissions before test
- ✅ Native watcher detects and dismisses dialogs
- ✅ **Zero manual intervention needed during tests**
- ✅ Native events logged and reported
- ✅ **Google Credential Picker automatically dismissed**

### **Phase 3 Success:**

- ✅ Can run 10+ tests in parallel on 4 devices
- ✅ Flaky tests pass with retry logic
- ✅ Screenshots captured on failure
- ✅ Video recording works

### **Phase 4 Success:**

- ✅ Generates beautiful HTML reports
- ✅ JUnit XML compatible with CI/CD
- ✅ GitHub Actions integration works
- ✅ Complete documentation published

---

## 🎯 **Example Usage**

### **Basic Usage:**

```bash
flutter_test_pilot run integration_test/login_test.dart
```

### **Full-Featured Run:**

```bash
flutter_test_pilot run integration_test/ \
  --parallel=4 \
  --devices=auto \
  --pre-grant-permissions=all \
  --native-watcher=enabled \
  --retry-failures=3 \
  --retry-delay=5s \
  --report=html,json,junit \
  --screenshot-on-failure \
  --video-recording \
  --performance-profiling \
  --tags=smoke,regression
```

### **CI/CD Usage:**

```bash
flutter_test_pilot run integration_test/ \
  --ci-mode \
  --no-color \
  --machine-output \
  --exit-on-failure \
  --report=junit \
  --screenshot-on-failure \
  --pre-grant-all \
  --native-watcher=enabled
```

---

## 🔥 **Key Innovation: Native Dialog Handling**

### **The Problem:**

```dart
// Your integration test
testWidgets('Login flow', (tester) async {
  await tester.tap(find.text('Login with Google'));

  // 😫 Google Credential Picker appears!
  // ❌ Test hangs forever - can't dismiss it!
});
```

### **The Solution:**

**Before Test Starts:**

```bash
# Your CLI pre-grants permissions
adb shell pm grant com.your.app android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.your.app android.permission.CAMERA
# ... etc
```

**During Test Execution:**

```
Process 1 (Test):          Process 2 (Watcher):
│                          │
├─ Test starts             ├─ Watcher starts
├─ Tap "Login"            ├─ Polling for dialogs...
├─ Dialog appears! 🚨      ├─ Detected dialog! 🚨
│                          ├─ Press back button
│                          ├─ Wait 500ms
│                          ├─ Log event
├─ Dialog gone!           ├─ Continue polling...
├─ Continue test          │
└─ ✅ Test passes         └─ Watcher active
```

**Result:** 🎉 **Zero interruptions, tests run smoothly!**

---

## 💰 **Estimated Effort**

| Phase                      | Duration    | Complexity      | Risk           |
| -------------------------- | ----------- | --------------- | -------------- |
| Phase 1: Foundation        | 2 weeks     | Medium          | Low            |
| Phase 2: Native Actions    | 1 week      | **High**        | **Medium**     |
| Phase 3: Advanced Features | 1 week      | Medium          | Low            |
| Phase 4: Reporting & CI/CD | 2 weeks     | Low             | Low            |
| **Total**                  | **6 weeks** | **Medium-High** | **Low-Medium** |

---

## ⚠️ **Risks & Mitigation**

### **Risk 1: UI Automator Complexity**

- **Impact:** High
- **Probability:** Medium
- **Mitigation:**
  - Start with simple watcher (back button only)
  - Incrementally add dialog types
  - Fallback to manual if watcher fails

### **Risk 2: Cross-Platform Support**

- **Impact:** Medium
- **Probability:** Low
- **Mitigation:**
  - Focus on Android first (your primary use case)
  - Add iOS support in Phase 5 (future)
  - Test on macOS/Windows/Linux

### **Risk 3: Flutter SDK Changes**

- **Impact:** Low
- **Probability:** Low
- **Mitigation:**
  - Pin Flutter version in requirements
  - Test on multiple Flutter versions
  - Add version compatibility checks

---

## 📚 **Dependencies**

### **Dart Packages:**

```yaml
dependencies:
  args: ^2.4.0 # CLI argument parsing
  path: ^1.8.3 # File path utilities
  yaml: ^3.1.2 # Parse .testpilot.yaml
  mason_logger: ^0.2.9 # Beautiful console output
  process_run: ^0.14.2 # Process management
  collection: ^1.17.2 # Collection utilities
  meta: ^1.9.1 # Annotations

dev_dependencies:
  test: ^1.24.0 # Unit testing
  mockito: ^5.4.0 # Mocking
  build_runner: ^2.4.0 # Code generation
```

### **External Tools:**

- ✅ **ADB** (Android Debug Bridge) - Already available
- ✅ **Java 11+** (for UI Automator compilation) - Check in doctor
- ✅ **Flutter SDK** - Already available
- ⚠️ **UI Automator SDK** - Download if missing

---

## 🎯 **Next Steps (This Week)**

### **Day 1-2:**

1. ✅ Create package structure
2. ✅ Setup `bin/flutter_test_pilot.dart`
3. ✅ Implement basic command runner
4. ✅ Add `--help` and `--version`

### **Day 3-4:**

5. ✅ Implement device manager
6. ✅ Test on your Android emulator
7. ✅ Create device info models

### **Day 5-7:**

8. ✅ Build basic test executor
9. ✅ Test on your `login_test.dart`
10. ✅ Verify it works end-to-end

**Goal:** By end of Week 1, you should be able to run:

```bash
flutter_test_pilot run integration_test/login_test.dart
```

And see it execute on your emulator!

---

## ✅ **Decision Points**

Before starting, confirm:

1. ✅ **Focus on Android first?** (iOS later)
2. ✅ **Use UI Automator for native handling?** (vs manual ADB)
3. ✅ **Target pub.dev publication?** (vs internal tool)
4. ✅ **Open source?** (vs proprietary)

---

## 🎉 **Final Deliverable**

A CLI tool that transforms this:

```bash
# Current: Manual, error-prone
flutter test integration_test/login_test.dart
# ❌ Hangs on credential picker
# ❌ No native control
# ❌ No retry logic
```

Into this:

```bash
# Future: Automated, reliable
flutter_test_pilot run integration_test/login_test.dart \
  --pre-grant-all \
  --native-watcher=enabled \
  --retry-failures=3 \
  --screenshot-on-failure \
  --report=html,junit

# ✅ All permissions pre-granted
# ✅ Native dialogs auto-dismissed
# ✅ Automatic retries on failure
# ✅ Beautiful reports generated
# ✅ CI/CD ready
```

---

## 📞 **Contact & Support**

**Project Lead:** Jayprakash Pal  
**Status:** Planning Phase  
**Next Review:** End of Week 1 (Phase 1 Complete)

---

**Ready to revolutionize Flutter testing! 🚀**
