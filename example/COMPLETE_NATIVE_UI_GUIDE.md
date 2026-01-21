# 🎯 Complete Native & UI Handling Guide

## 📚 Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Two-Layer Approach](#two-layer-approach)
4. [Setup & Installation](#setup--installation)
5. [Complete Examples](#complete-examples)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Overview

Flutter Test Pilot provides **TWO layers** of dialog/permission handling:

### 🔵 Layer 1: Flutter-Side Handler
- **Location:** Runs inside Flutter test (Dart code)
- **Handles:** Flutter widgets, bottom sheets, Material/Cupertino dialogs
- **Technology:** `WidgetTester` + `flutter_test`
- **When:** Always active during tests

### 🟢 Layer 2: Native-Side Watcher
- **Location:** Runs on Android device (Java code)
- **Handles:** System dialogs, OS permissions, Google Sign-In picker
- **Technology:** UI Automator + ADB
- **When:** Optionally started for integration tests

```
┌─────────────────────────────────────────────────────────┐
│                    YOUR FLUTTER APP                      │
└─────────────────────────────────────────────────────────┘
           │                              │
           │ Flutter Widgets              │ Native Dialogs
           │ (Dart/Flutter)               │ (Android System)
           ▼                              ▼
┌──────────────────────┐      ┌──────────────────────────┐
│  Layer 1: Flutter    │      │  Layer 2: Native         │
│  UI Handler          │      │  Watcher                 │
│                      │      │                          │
│  • Bottom sheets     │      │  • System permissions    │
│  • Material dialogs  │      │  • Google Sign-In        │
│  • Cupertino alerts  │      │  • ANR dialogs          │
│  • Permission UI     │      │  • System alerts        │
│  • Custom widgets    │      │  • Native pickers       │
│                      │      │                          │
│  Runs: In Flutter    │      │  Runs: On Android       │
│  Tech: WidgetTester  │      │  Tech: UI Automator     │
└──────────────────────┘      └──────────────────────────┘
```

---

## Architecture

### How They Work Together

```
┌────────────────────────────────────────────────────────────┐
│                     YOUR TEST CODE                          │
│  IntegrationTestWidgetsFlutterBinding.ensureInitialized()  │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────┐
            │  Should I handle native dialogs?│
            └─────────────────┬───────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                YES │                   │ NO
                    ▼                   ▼
        ┌──────────────────┐    ┌──────────────┐
        │ Start Native     │    │ Flutter-only │
        │ Watcher (Layer 2)│    │ (Layer 1)    │
        └──────────────────┘    └──────────────┘
                    │
                    ▼
        ┌──────────────────────────┐
        │  Configure Watcher       │
        │  • Allow/Deny?           │
        │  • Precise/Approximate?  │
        │  • Notifications?        │
        └──────────────────────────┘
                    │
                    ▼
        ┌──────────────────────────┐
        │  RUN YOUR TEST           │
        │                          │
        │  Layer 1: Always active  │
        │  Layer 2: If started     │
        └──────────────────────────┘
```

---

## Two-Layer Approach

### 🔵 Layer 1: Flutter UI Handler (NativeActionHandler)

**What it handles:**
- ✅ Bottom sheets (Android auto-fill, permission UI)
- ✅ Material dialogs (AlertDialog, SimpleDialog)
- ✅ Cupertino dialogs (iOS-style)
- ✅ Phone picker bottom sheets
- ✅ Custom Flutter widgets with text like "Allow"
- ✅ Permission-related buttons in Flutter UI
- ✅ ANR detection (basic)

**How to use:**
```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

testWidgets('My test', (tester) async {
  // AUTOMATICALLY ACTIVE - No setup needed!
  
  // Start monitoring (optional - for aggressive handling)
  NativeActionHandler.instance.startMonitoring(tester);
  
  // Your test code
  app.main();
  await tester.pumpAndSettle();
  
  // Handler will automatically click "Allow" buttons, 
  // dismiss bottom sheets, etc.
  
  // Stop monitoring when done
  NativeActionHandler.instance.stopMonitoring();
});
```

**Key Features:**
- 🚀 **Automatic** - Runs in background every 300ms
- 🎯 **Multiple strategies** - Tries different tap methods
- 🔄 **Conflict detection** - Pauses during test actions
- 📱 **Bottom sheet support** - Critical for Android permissions

---

### 🟢 Layer 2: Native Watcher (Java UI Automator)

**What it handles:**
- ✅ System permission dialogs (outside Flutter)
- ✅ Google Sign-In credential picker
- ✅ Android location precision dialog
- ✅ Notification permission (system level)
- ✅ System alerts ("OK", "Continue", "Got it")
- ✅ ANR dialogs ("App not responding")
- ✅ Native platform views

**How to use:**
```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

testWidgets('Test with native support', (tester) async {
  final handler = NativeHandler();
  final deviceId = 'emulator-5554';
  
  // STEP 1: Configure watcher behavior
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.allow,  // Your choice!
    locationPrecision: LocationPrecision.precise,
    notificationAction: DialogAction.allow,
  );
  
  // STEP 2: Start native watcher
  final watcherProcess = await DialogWatcher(AdbCommander()).start(deviceId);
  
  // STEP 3: Run your test
  app.main();
  await tester.pumpAndSettle();
  
  // Both layers now work together!
  
  // STEP 4: Stop watcher
  await DialogWatcher(AdbCommander()).stop(watcherProcess);
  await handler.clearWatcherConfig(deviceId);
});
```

**Key Features:**
- 🎮 **Test-driven** - You control behavior (allow/deny/ignore)
- 🔄 **Auto-reload** - Checks config every 5 seconds
- 📊 **Statistics** - Reports dialogs detected/dismissed
- 🎯 **Precise control** - Different action per dialog type

---

## Setup & Installation

### Prerequisites

```bash
# 1. Install Android SDK
brew install --cask android-platform-tools

# 2. Add to PATH
export PATH=$PATH:~/Library/Android/sdk/platform-tools

# 3. Verify ADB
adb version
```

### Project Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_test_pilot: ^1.0.0

dev_dependencies:
  integration_test: ^0.13.0
  flutter_test:
    sdk: flutter
```

### Build Native Watcher (One-time)

```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/native_assets/android

# Install Gradle wrapper
gradle wrapper --gradle-version 8.5

# Build the watcher JAR
./gradlew buildWatcherJar

# Output: build/libs/native_watcher.jar
```

---

## Complete Examples

### Example 1: Flutter-Only Test (Layer 1 Only)

**Use when:** Testing apps without system permissions

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Simple Flutter UI test', (tester) async {
    // Layer 1 (Flutter Handler) is AUTOMATICALLY active!
    
    // Start your app
    runApp(MyApp());
    await tester.pumpAndSettle();
    
    // Tap a button that shows a Flutter dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
    
    // Layer 1 will automatically find and tap "OK" if it's a dialog
    // Or you can verify manually:
    expect(find.text('Are you sure?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    
    // That's it! No native watcher needed.
  });
}
```

---

### Example 2: Full Native Support (Both Layers)

**Use when:** Testing apps with location, camera, or other system permissions

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Location Permission Tests', () {
    final handler = NativeHandler();
    final adb = AdbCommander();
    late String deviceId;
    late Process watcherProcess;

    setUpAll(() async {
      // Get device ID
      final devices = await adb.getDevices();
      deviceId = devices.first;
      print('📱 Using device: $deviceId');
    });

    setUp(() async {
      // Configure watcher BEFORE each test
      await handler.configureWatcher(
        deviceId: deviceId,
        permissionAction: DialogAction.allow,
        locationPrecision: LocationPrecision.precise,
      );
      
      // Start watcher
      watcherProcess = await DialogWatcher(adb).start(deviceId);
      print('🤖 Native watcher started');
    });

    tearDown(() async {
      // Stop watcher AFTER each test
      await DialogWatcher(adb).stop(watcherProcess);
      await handler.clearWatcherConfig(deviceId);
      print('🛑 Native watcher stopped');
    });

    testWidgets('Test location permission grant', (tester) async {
      // Layer 1: Active (Flutter UI)
      // Layer 2: Active (Native dialogs)
      
      // Start app
      runApp(MyApp());
      await tester.pumpAndSettle();
      
      // Tap "Get Location" button
      await tester.tap(find.text('Get My Location'));
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // What happens:
      // 1. App requests location permission
      // 2. System shows permission dialog (outside Flutter)
      // 3. Layer 2 (Native Watcher) detects it
      // 4. Watcher clicks "Allow" (as configured)
      // 5. App receives permission
      
      // Verify app got permission
      await tester.pump(Duration(seconds: 1));
      expect(find.text('Location: 37.7749° N'), findsOneWidget);
      
      print('✅ Location permission granted successfully');
    });
  });
}
```

---

### Example 3: Test Both Grant and Denial

**Use when:** Testing how your app handles both scenarios

```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Permission Flow Tests', () {
    final handler = NativeHandler();
    final adb = AdbCommander();
    late String deviceId;

    setUpAll(() async {
      deviceId = (await adb.getDevices()).first;
    });

    testWidgets('Scenario 1: User grants permission', (tester) async {
      // Configure: ALLOW
      await handler.configureWatcher(
        deviceId: deviceId,
        permissionAction: DialogAction.allow,
      );
      
      final watcherProcess = await DialogWatcher(adb).start(deviceId);
      
      runApp(MyApp());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Request Camera'));
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Verify success flow
      expect(find.text('Camera Ready'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      
      await DialogWatcher(adb).stop(watcherProcess);
      await handler.clearWatcherConfig(deviceId);
    });

    testWidgets('Scenario 2: User denies permission', (tester) async {
      // Configure: DENY
      await handler.configureWatcher(
        deviceId: deviceId,
        permissionAction: DialogAction.deny,
      );
      
      final watcherProcess = await DialogWatcher(adb).start(deviceId);
      
      runApp(MyApp());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Request Camera'));
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Verify error handling
      expect(find.text('Camera permission denied'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
      
      await DialogWatcher(adb).stop(watcherProcess);
      await handler.clearWatcherConfig(deviceId);
    });
  });
}
```

---

### Example 4: Complex Multi-Permission Flow

**Use when:** Testing complex apps with multiple permissions

```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete app flow with multiple permissions', (tester) async {
    final handler = NativeHandler();
    final adb = AdbCommander();
    final deviceId = (await adb.getDevices()).first;
    
    // Configure: Grant permissions but deny notifications
    await handler.configureWatcher(
      deviceId: deviceId,
      permissionAction: DialogAction.allow,        // ✅ Camera, Location, etc.
      notificationAction: DialogAction.deny,      // ❌ Notifications
      locationPrecision: LocationPrecision.precise,
      systemDialogAction: DialogAction.dismiss,
    );
    
    final watcherProcess = await DialogWatcher(adb).start(deviceId);
    
    print('🎬 Starting complex flow test');
    
    // PHASE 1: Launch app
    runApp(MyApp());
    await tester.pumpAndSettle();
    print('✅ App launched');
    
    // PHASE 2: Login (may trigger Google Sign-In picker)
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle(Duration(seconds: 3));
    // Layer 2 will dismiss Google picker automatically
    print('✅ Login handled');
    
    // PHASE 3: Request location
    await tester.tap(find.text('Enable Location'));
    await tester.pumpAndSettle(Duration(seconds: 2));
    // Layer 2 will click "Allow" and select "Precise"
    expect(find.text('Location enabled'), findsOneWidget);
    print('✅ Location granted');
    
    // PHASE 4: Request camera
    await tester.tap(find.text('Upload Photo'));
    await tester.pumpAndSettle(Duration(seconds: 2));
    // Layer 2 will click "Allow"
    expect(find.byIcon(Icons.camera), findsOneWidget);
    print('✅ Camera granted');
    
    // PHASE 5: Request notifications
    await tester.tap(find.text('Enable Notifications'));
    await tester.pumpAndSettle(Duration(seconds: 2));
    // Layer 2 will click "Deny"
    expect(find.text('Notifications disabled'), findsOneWidget);
    print('❌ Notifications denied (as configured)');
    
    // PHASE 6: Complete flow
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    print('✅ Flow complete!');
    
    // Cleanup
    await DialogWatcher(adb).stop(watcherProcess);
    await handler.clearWatcherConfig(deviceId);
  });
}
```

---

### Example 5: Using Extension Methods

**Simplified API for common operations**

```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Using extension methods', (tester) async {
    runApp(MyApp());
    await tester.pumpAndSettle();
    
    // Extension methods on WidgetTester
    
    // Handle all startup permissions at once
    await tester.handleStartupPermissions();
    
    // Grant specific permission
    await tester.grantLocationPermission();
    
    // Grant notification permission
    await tester.grantNotificationPermission();
    
    // Recover from ANR
    await tester.recoverFromANR();
    
    // Wait for app to be responsive
    await tester.waitUntilResponsive(timeout: Duration(seconds: 30));
    
    // Dismiss any visible dialog
    await tester.dismissDialogs();
  });
}
```

---

## Best Practices

### ✅ DO: Clear Configuration Between Tests

```dart
tearDown(() async {
  await handler.clearWatcherConfig(deviceId);
  // This prevents test interference
});
```

### ✅ DO: Be Explicit About Intent

```dart
// GOOD - Clear what test expects
await handler.configureWatcher(
  deviceId: deviceId,
  permissionAction: DialogAction.allow,  // Explicitly allow
  locationPrecision: LocationPrecision.precise,
);

// BAD - Unclear intent
await handler.configureWatcher(deviceId: deviceId);
```

### ✅ DO: Use Appropriate Wait Times

```dart
// After permission request, wait for dialog
await tester.tap(find.text('Request Permission'));
await tester.pumpAndSettle(Duration(seconds: 2)); // Give time for system dialog

// After watcher action, wait for UI update
await tester.pump(Duration(milliseconds: 500));
```

### ✅ DO: Check Device Capabilities

```dart
final capabilities = await handler.checkCapabilities(deviceId);
if (!capabilities.watcherSupported) {
  print('⚠️  UI Automator not supported, skipping native tests');
  return;
}
```

### ❌ DON'T: Start Watcher After Test Begins

```dart
// ❌ WRONG - Too late!
runApp(MyApp());
await tester.pumpAndSettle();
final watcherProcess = await watcher.start(deviceId); // Dialog already missed!

// ✅ CORRECT - Start before app
final watcherProcess = await watcher.start(deviceId);
runApp(MyApp());
await tester.pumpAndSettle();
```

### ❌ DON'T: Forget to Stop Watcher

```dart
// ❌ WRONG - Watcher keeps running
testWidgets('My test', (tester) async {
  final watcherProcess = await watcher.start(deviceId);
  // ... test code ...
  // Forgot to stop!
});

// ✅ CORRECT - Always stop
testWidgets('My test', (tester) async {
  final watcherProcess = await watcher.start(deviceId);
  try {
    // ... test code ...
  } finally {
    await watcher.stop(watcherProcess);
  }
});
```

---

## Decision Tree: Which Layer Do I Need?

```
┌──────────────────────────────────────┐
│ Does your test need to handle        │
│ SYSTEM permissions (location,        │
│ camera, notifications)?              │
└────────────┬─────────────────────────┘
             │
      ┌──────┴──────┐
      │             │
     YES            NO
      │             │
      ▼             ▼
┌─────────────┐  ┌──────────────┐
│ Use BOTH    │  │ Use Layer 1  │
│ Layers      │  │ ONLY         │
│             │  │              │
│ Layer 1: ✅ │  │ Layer 1: ✅  │
│ Layer 2: ✅ │  │ Layer 2: ❌  │
└─────────────┘  └──────────────┘
      │                 │
      ▼                 ▼
┌─────────────────┐  ┌──────────────────┐
│ Start Native    │  │ No extra setup   │
│ Watcher         │  │ needed!          │
│                 │  │                  │
│ Configure it    │  │ Handler works    │
│ per test        │  │ automatically    │
└─────────────────┘  └──────────────────┘
```

---

## Troubleshooting

### Problem: Native watcher not handling dialogs

**Symptoms:**
- Test hangs when permission dialog appears
- Dialog stays on screen

**Solutions:**

1. **Check watcher is running:**
```bash
adb logcat -s TestPilotWatcher
# Should see: "🤖 Native watcher started"
```

2. **Verify configuration:**
```dart
// Make sure you configured BEFORE starting
await handler.configureWatcher(...);  // First
final watcherProcess = await watcher.start(deviceId);  // Then
```

3. **Check device support:**
```dart
final capabilities = await handler.checkCapabilities(deviceId);
print('Watcher supported: ${capabilities.watcherSupported}');
```

---

### Problem: Flutter handler not clicking buttons

**Symptoms:**
- Bottom sheets not dismissed
- "Allow" buttons not clicked

**Solutions:**

1. **Enable monitoring explicitly:**
```dart
NativeActionHandler.instance.startMonitoring(tester);
```

2. **Add sufficient wait time:**
```dart
await tester.pumpAndSettle(Duration(seconds: 2));
```

3. **Check widget visibility:**
```dart
// Use skipOffstage: false
final finder = find.text('Allow', skipOffstage: false);
print('Found: ${tester.any(finder)}');
```

---

### Problem: Configuration not applied

**Symptoms:**
- Watcher uses default behavior
- Logs show "No test configuration found"

**Solutions:**

1. **Check file permissions:**
```bash
adb shell ls -l /sdcard/flutter_test_pilot_watcher_config.json
```

2. **Verify JSON format:**
```dart
// Check logs for parse errors
adb logcat -s TestPilotWatcher | grep "Error loading configuration"
```

3. **Wait after configuration:**
```dart
await handler.configureWatcher(...);
await Future.delayed(Duration(seconds: 1));  // Give time to write
final watcherProcess = await watcher.start(deviceId);
```

---

### Problem: Tests interfere with each other

**Symptoms:**
- Second test uses first test's configuration
- Unexpected permission behavior

**Solutions:**

```dart
tearDown(() async {
  // ALWAYS clear config
  await handler.clearWatcherConfig(deviceId);
  
  // ALWAYS stop watcher
  if (watcherProcess != null) {
    await watcher.stop(watcherProcess);
  }
});
```

---

## Quick Reference

### Layer 1 (Flutter UI Handler)

| Feature | Code |
|---------|------|
| Auto-start | Enabled by default |
| Manual start | `NativeActionHandler.instance.startMonitoring(tester)` |
| Manual stop | `NativeActionHandler.instance.stopMonitoring()` |
| Handle location | `await tester.grantLocationPermission()` |
| Handle notification | `await tester.grantNotificationPermission()` |
| Dismiss dialogs | `await tester.dismissDialogs()` |

### Layer 2 (Native Watcher)

| Feature | Code |
|---------|------|
| Configure | `await handler.configureWatcher(deviceId: ..., permissionAction: ...)` |
| Start | `final process = await DialogWatcher(adb).start(deviceId)` |
| Stop | `await DialogWatcher(adb).stop(process)` |
| Clear config | `await handler.clearWatcherConfig(deviceId)` |
| Check support | `final caps = await handler.checkCapabilities(deviceId)` |

---

## Summary

### When to Use Each Layer

| Scenario | Layer 1 | Layer 2 |
|----------|---------|---------|
| Flutter dialogs | ✅ | ❌ |
| Bottom sheets | ✅ | ❌ |
| Custom widgets | ✅ | ❌ |
| System permissions | ❌ | ✅ |
| Google Sign-In | ❌ | ✅ |
| ANR dialogs | ⚠️ Basic | ✅ Full |
| Location precision | ❌ | ✅ |

### Configuration Options

```dart
await handler.configureWatcher(
  deviceId: deviceId,
  
  // Permission dialogs
  permissionAction: DialogAction.allow,  // allow | deny | dismiss | ignore
  
  // Location
  locationPrecision: LocationPrecision.precise,  // precise | approximate
  
  // Notifications
  notificationAction: DialogAction.allow,  // allow | deny | ignore
  
  // System dialogs
  systemDialogAction: DialogAction.dismiss,  // dismiss | ignore
  
  // Google picker
  dismissGooglePicker: true,  // true | false
);
```

---

## 🎉 You're Ready!

You now understand:
- ✅ Two-layer architecture
- ✅ When to use each layer
- ✅ How to configure native watcher
- ✅ How to write comprehensive tests
- ✅ Best practices and troubleshooting

**Next Steps:**
1. Try the examples in this folder
2. Read `test_driven_watcher_guide.md` for advanced scenarios
3. Check `native_action_handler_guide.md` for Layer 1 details
4. Build your own tests!

**Happy Testing! 🚀**
