# 🎯 Test-Driven Native Watcher - Complete Guide

## Overview

The Native Watcher now supports **test-driven configuration**! Your Flutter tests can control exactly how the watcher handles native dialogs.

## ✅ What Changed

### Before (Hard-Coded):
```java
// Always clicks "Allow"
allowButton.click();
```

### After (Test-Driven):
```java
// Reads configuration from test
if (config.permissionAction.equals("allow")) {
    allowButton.click();
} else if (config.permissionAction.equals("deny")) {
    denyButton.click();
}
```

---

## 🚀 How to Use in Your Tests

### 1. Basic Example - Allow Permissions

```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  testWidgets('Test with permissions allowed', (tester) async {
    final handler = NativeHandler();
    final deviceId = 'emulator-5554';
    
    // Configure watcher BEFORE starting it
    await handler.configureWatcher(
      deviceId: deviceId,
      permissionAction: DialogAction.allow,  // ✅ Grant all permissions
      locationPrecision: LocationPrecision.precise,
      notificationAction: DialogAction.allow,
    );
    
    // Start watcher - it will now follow your configuration
    final watcherProcess = await DialogWatcher(AdbCommander()).start(deviceId);
    
    // Run your test
    app.main();
    await tester.pumpAndSettle();
    
    // Test knows permissions will be auto-granted!
    await tester.tap(find.text('Request Location'));
    await tester.pumpAndSettle();
    
    // Stop watcher
    await DialogWatcher(AdbCommander()).stop(watcherProcess);
  });
}
```

---

### 2. Example - Deny Permissions

```dart
testWidgets('Test permission denial flow', (tester) async {
  final handler = NativeHandler();
  final deviceId = 'emulator-5554';
  
  // Configure watcher to DENY permissions
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.deny,  // ❌ Deny all permissions
    notificationAction: DialogAction.deny,
  );
  
  final watcherProcess = await DialogWatcher(AdbCommander()).start(deviceId);
  
  app.main();
  await tester.pumpAndSettle();
  
  // Request permission
  await tester.tap(find.text('Request Camera'));
  await tester.pumpAndSettle();
  
  // Verify app handles denial correctly
  expect(find.text('Camera permission denied'), findsOneWidget);
  
  await DialogWatcher(AdbCommander()).stop(watcherProcess);
});
```

---

### 3. Example - Ignore Dialogs (Don't Handle)

```dart
testWidgets('Test manual permission handling', (tester) async {
  final handler = NativeHandler();
  final deviceId = 'emulator-5554';
  
  // Tell watcher to IGNORE permissions
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.ignore,  // 🚫 Don't touch permissions
  );
  
  // Watcher won't handle permission dialogs
  // You can handle them manually in your test
});
```

---

### 4. Example - Location Precision

```dart
testWidgets('Test with approximate location', (tester) async {
  final handler = NativeHandler();
  final deviceId = 'emulator-5554';
  
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.allow,
    locationPrecision: LocationPrecision.approximate,  // 📍 Select "Approximate"
  );
  
  // Watcher will select "Approximate" instead of "Precise"
});
```

---

### 5. Complete Example with Native Handler

```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  testWidgets('Complete flow with test-driven watcher', (tester) async {
    final handler = NativeHandler();
    final deviceId = 'emulator-5554';
    final packageName = 'com.example.myapp';
    
    // Step 1: Configure watcher behavior
    await handler.configureWatcher(
      deviceId: deviceId,
      permissionAction: DialogAction.allow,
      locationPrecision: LocationPrecision.precise,
      notificationAction: DialogAction.allow,
      systemDialogAction: DialogAction.dismiss,
      dismissGooglePicker: true,
    );
    
    // Step 2: Run test with native support
    final result = await handler.runWithNativeSupport(
      deviceId: deviceId,
      testFile: 'integration_test/my_test.dart',
      packageName: packageName,
      options: NativeOptions(
        packageName: packageName,
        permissionMode: PermissionMode.all,
        enableWatcher: true,
      ),
      testRunner: () async {
        // Your actual test code
        app.main();
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        
        expect(find.text('Welcome'), findsOneWidget);
        
        return TestResult(
          testPath: 'integration_test/my_test.dart',
          testHash: 'test123',
          passed: true,
          duration: Duration(seconds: 5),
          timestamp: DateTime.now(),
          deviceId: deviceId,
        );
      },
    );
    
    // Step 3: Clean up configuration
    await handler.clearWatcherConfig(deviceId);
    
    expect(result.passed, true);
  });
}
```

---

## 📋 Configuration Options

### DialogAction Enum

| Value | Behavior |
|-------|----------|
| `DialogAction.allow` | Click "Allow" / positive action |
| `DialogAction.deny` | Click "Deny" / negative action |
| `DialogAction.dismiss` | Dismiss via back button |
| `DialogAction.ignore` | Don't handle this type of dialog |

### LocationPrecision Enum

| Value | Behavior |
|-------|----------|
| `LocationPrecision.precise` | Select "Precise" location |
| `LocationPrecision.approximate` | Select "Approximate" location |

---

## 🔄 How It Works

### Architecture

```
┌─────────────────────┐
│   Flutter Test      │
│                     │
│  configureWatcher() │
└──────────┬──────────┘
           │
           │ Writes JSON to device
           ▼
    ┌─────────────────┐
    │  Device Storage │
    │  /sdcard/       │
    │  config.json    │
    └────────┬────────┘
             │
             │ Reads every 5 seconds
             ▼
    ┌────────────────────┐
    │  Native Watcher    │
    │  (Java)            │
    │                    │
    │  if (allow) click  │
    │  if (deny) dismiss │
    └────────────────────┘
```

### Configuration File Example

```json
{
  "permissions": "allow",
  "location": "precise",
  "notifications": "deny",
  "systemDialogs": "dismiss",
  "googlePicker": "dismiss",
  "timestamp": 1642784520000
}
```

---

## �� Real-World Scenarios

### Scenario 1: Test Permission Grant Flow

```dart
testWidgets('User grants location permission', (tester) async {
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.allow,  // ✅ Auto-grant
    locationPrecision: LocationPrecision.precise,
  );
  
  // Test flow after permission granted
  await tester.tap(find.text('Get My Location'));
  await tester.pumpAndSettle();
  
  expect(find.text('Location: 37.7749° N'), findsOneWidget);
});
```

### Scenario 2: Test Permission Denial Flow

```dart
testWidgets('User denies location permission', (tester) async {
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.deny,  // ❌ Auto-deny
  );
  
  // Test how app handles denial
  await tester.tap(find.text('Get My Location'));
  await tester.pumpAndSettle();
  
  expect(find.text('Location permission is required'), findsOneWidget);
  expect(find.text('Go to Settings'), findsOneWidget);
});
```

### Scenario 3: Mixed Permissions

```dart
testWidgets('Allow location but deny notifications', (tester) async {
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.allow,      // Location: YES
    notificationAction: DialogAction.deny,    // Notifications: NO
  );
  
  // Test mixed permission state
});
```

---

## 📊 Watcher Logs

### Before (Generic)
```
🚨 Detected: Permission Dialog (Allow button)
✅ Granted permission
```

### After (Test-Driven)
```
📝 Configuration loaded from test:
   Permissions: deny
   Location: approximate
   Notifications: allow
   
🚨 Detected: Permission Dialog (Allow button)
   Test directive: deny
❌ Denied permission (as per test config)
```

---

## 🐛 Troubleshooting

### Issue: Configuration Not Applied

**Problem:** Watcher still uses default behavior

**Solution:** Make sure to configure BEFORE starting the watcher:

```dart
// ✅ CORRECT
await handler.configureWatcher(...);
final watcherProcess = await watcher.start(deviceId);

// ❌ WRONG
final watcherProcess = await watcher.start(deviceId);
await handler.configureWatcher(...);  // Too late!
```

### Issue: Configuration Not Clearing

**Problem:** Old configuration affects new test

**Solution:** Always clear config after test:

```dart
tearDown(() async {
  await handler.clearWatcherConfig(deviceId);
});
```

---

## 🎯 Best Practices

### 1. **Configure Per Test**
```dart
setUp(() async {
  await handler.configureWatcher(
    deviceId: deviceId,
    // Test-specific configuration
  );
});

tearDown(() async {
  await handler.clearWatcherConfig(deviceId);
});
```

### 2. **Be Explicit**
```dart
// ✅ GOOD - Clear intent
await handler.configureWatcher(
  deviceId: deviceId,
  permissionAction: DialogAction.allow,
  locationPrecision: LocationPrecision.precise,
);

// ❌ BAD - Relying on defaults
await handler.configureWatcher(deviceId: deviceId);
```

### 3. **Document Intent**
```dart
testWidgets('Test with denied permissions', (tester) async {
  // IMPORTANT: This test verifies the app gracefully handles
  // permission denial and shows appropriate error messages
  await handler.configureWatcher(
    deviceId: deviceId,
    permissionAction: DialogAction.deny,
  );
  
  // ... test code
});
```

---

## 🚀 Migration Guide

### Old Approach (Pre-Configuration)

```dart
// Old: Watcher always granted permissions
final watcherProcess = await watcher.start(deviceId);

// Hope it grants permissions...
await tester.tap(find.text('Request Permission'));
```

### New Approach (Test-Driven)

```dart
// New: Test explicitly controls behavior
await handler.configureWatcher(
  deviceId: deviceId,
  permissionAction: DialogAction.allow,  // Test says: grant
);

final watcherProcess = await watcher.start(deviceId);

// Now we KNOW it will grant permissions
await tester.tap(find.text('Request Permission'));
```

---

## ✅ Summary

| Feature | Before | After |
|---------|--------|-------|
| Permission Handling | Always allow | Test decides (allow/deny/ignore) |
| Location Precision | Always precise | Test decides (precise/approximate) |
| Notifications | Always allow | Test decides (allow/deny) |
| System Dialogs | Always dismiss | Test decides (dismiss/ignore) |
| Flexibility | ❌ None | ✅ Full control |
| Test Clarity | ❌ Implicit | ✅ Explicit |

---

## 📚 See Also

- [Native Handler Guide](./native_action_handler_guide.md)
- [Permission Granter Guide](./permission_granter_guide.md)
- [ADB Commander Guide](./adb_commander_guide.md)

---

**🎉 You now have complete control over native dialog handling in your tests!**
