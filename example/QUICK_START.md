# 🚀 Quick Start: Native + UI Handling

## 30-Second Overview

Flutter Test Pilot has **2 layers** that work together:

```
┌────────────────────────────────────────┐
│  Layer 1: Flutter UI Handler (Dart)   │ ← Handles Flutter widgets
│  - Always active automatically         │
│  - Bottom sheets, dialogs, buttons     │
└────────────────────────────────────────┘

┌────────────────────────────────────────┐
│  Layer 2: Native Watcher (Java)        │ ← Handles system dialogs
│  - Optional, needs setup                │
│  - Permissions, Google Sign-In, ANR    │
└────────────────────────────────────────┘
```

---

## 🎯 Choose Your Path

### Path A: Flutter-Only (No System Permissions)

```dart
// integration_test/simple_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('My test', (tester) async {
    // Layer 1 is AUTOMATICALLY active!
    // No setup needed.
    
    runApp(MyApp());
    await tester.pumpAndSettle();
    
    // Test your app...
  });
}
```

**Done! That's it for simple tests.**

---

### Path B: Full Native Support (System Permissions)

```dart
// integration_test/location_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test with location permission', (tester) async {
    // Setup
    final handler = NativeHandler();
    final adb = AdbCommander();
    final deviceId = (await adb.getDevices()).first;
    
    // Configure: Tell watcher what to do
    await handler.configureWatcher(
      deviceId: deviceId,
      permissionAction: DialogAction.allow,  // ✅ Grant permissions
    );
    
    // Start native watcher
    final watcherProcess = await DialogWatcher(adb).start(deviceId);
    
    // Run your test
    runApp(MyApp());
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Get Location'));
    await tester.pumpAndSettle(Duration(seconds: 2));
    
    // Verify
    expect(find.text('Location: 37.7749'), findsOneWidget);
    
    // Cleanup
    await DialogWatcher(adb).stop(watcherProcess);
    await handler.clearWatcherConfig(deviceId);
  });
}
```

---

## 🔧 One-Time Setup (For Path B)

### 1. Build Native Watcher

```bash
cd /Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new/iltc-services/flutter_test_pilot/native_assets/android

# Install wrapper
gradle wrapper --gradle-version 8.5

# Build
./gradlew buildWatcherJar

# Check output
ls -lh build/libs/native_watcher.jar
```

### 2. Connect Device

```bash
# Start emulator or connect device
adb devices

# Should show:
# emulator-5554   device
```

---

## 📋 Configuration Cheat Sheet

```dart
await handler.configureWatcher(
  deviceId: deviceId,
  
  // Options (choose what you need):
  permissionAction: DialogAction.allow,  // allow | deny | ignore
  locationPrecision: LocationPrecision.precise,  // precise | approximate
  notificationAction: DialogAction.allow,  // allow | deny | ignore
);
```

---

## 🎯 Common Scenarios

### ✅ Grant All Permissions

```dart
await handler.configureWatcher(
  deviceId: deviceId,
  permissionAction: DialogAction.allow,
  notificationAction: DialogAction.allow,
);
```

### ❌ Deny All Permissions

```dart
await handler.configureWatcher(
  deviceId: deviceId,
  permissionAction: DialogAction.deny,
  notificationAction: DialogAction.deny,
);
```

### 🎭 Mixed (Grant Location, Deny Notifications)

```dart
await handler.configureWatcher(
  deviceId: deviceId,
  permissionAction: DialogAction.allow,
  notificationAction: DialogAction.deny,
);
```

---

## 🐛 Quick Troubleshooting

### Problem: Permission dialog not handled

**Check:**
```bash
# Is watcher running?
adb logcat -s TestPilotWatcher
```

**Fix:**
```dart
// Configure BEFORE starting
await handler.configureWatcher(...);  // First
final process = await watcher.start(deviceId);  // Then
```

### Problem: Test hangs

**Add wait time:**
```dart
await tester.pumpAndSettle(Duration(seconds: 2));
```

---

## 📚 Next Steps

1. ✅ Read `COMPLETE_NATIVE_UI_GUIDE.md` for full details
2. ✅ Check `test_driven_watcher_guide.md` for advanced config
3. ✅ Run example tests in `integration_test/` folder

---

**That's it! You're ready to test! 🎉**
