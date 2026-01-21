# Native Action Handler - Complete Guide

## 🛡️ Overview

The **Native Action Handler** is a powerful component of Flutter Test Pilot that automatically handles native platform issues during integration tests, including:

- ✅ **ANR (Application Not Responding)** detection and recovery
- ✅ **Crash dialog** handling
- ✅ **Permission dialogs** (Location, Camera, Storage, Notifications, etc.)
- ✅ **System dialogs** (Updates, Battery optimization, etc.)
- ✅ **Background monitoring** for continuous protection
- ✅ **Automatic dialog dismissal**

---

## 🚀 Quick Start

### Basic Usage

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('My test with native protection', (WidgetTester tester) async {
    // Launch your app
    app.main();
    await tester.pumpAndSettle();

    // Handle all startup permissions automatically
    await tester.handleStartupPermissions();

    // Your test code here...
  });
}
```

---

## 📖 Extension Methods

The Native Action Handler provides convenient extension methods on `WidgetTester`:

### 1. **handleStartupPermissions()**

Handles all permissions that appear when the app starts.

```dart
await tester.handleStartupPermissions();
```

**What it handles:**

- Location permissions
- Camera permissions
- Storage permissions
- Notification permissions
- System dialogs
- Update dialogs

---

### 2. **grantLocationPermission()**

Specifically handles location permission dialogs.

```dart
await tester.grantLocationPermission();
```

**Handles these dialogs:**

- "Allow"
- "Allow only while using the app"
- "Allow all the time"
- "While using the app"
- "Only this time"

---

### 3. **grantNotificationPermission()**

Handles notification permission dialogs.

```dart
await tester.grantNotificationPermission();
```

---

### 4. **grantCameraPermission()**

Handles camera permission dialogs.

```dart
await tester.grantCameraPermission();
```

---

### 5. **grantStoragePermission()**

Handles storage/media permission dialogs.

```dart
await tester.grantStoragePermission();
```

---

### 6. **recoverFromANR()**

Detects and recovers from ANR (Application Not Responding) dialogs.

```dart
await tester.recoverFromANR();
```

**What it does:**

- Detects ANR dialog
- Taps "Wait" button
- Taps "OK" or "Close" if needed
- Prevents test failure

---

### 7. **recoverFromCrash()**

Handles app crash dialogs.

```dart
await tester.recoverFromCrash();
```

**Handles:**

- "App has stopped"
- "App has crashed"
- "Unfortunately, [app] has stopped"
- Error dialogs

---

### 8. **waitUntilResponsive()**

Waits for the app to become responsive.

```dart
await tester.waitUntilResponsive(timeout: Duration(seconds: 30));
```

---

### 9. **dismissDialogs()**

Dismisses any visible native dialog.

```dart
await tester.dismissDialogs();
```

---

## 🔥 Advanced Usage

### Background Monitoring

Start continuous monitoring for native issues:

```dart
testWidgets('Test with background monitoring', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Start monitoring (checks every 2 seconds)
  NativeActionHandler.instance.startMonitoring(tester);

  // Your long-running test...
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();

  // Monitoring automatically handles any dialogs that appear

  // Stop monitoring when done
  NativeActionHandler.instance.stopMonitoring();
});
```

---

### Complete E2E Test with Full Protection

```dart
testWidgets('Complete E2E with native protection', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 1. Start monitoring
  NativeActionHandler.instance.startMonitoring(tester);

  // 2. Handle startup permissions
  await tester.handleStartupPermissions();

  // 3. Navigate through app
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.recoverFromANR(); // Check for ANR

  // 4. Test location feature
  await tester.tap(find.text('Enable Location'));
  await tester.grantLocationPermission();

  // 5. Test camera feature
  await tester.tap(find.text('Take Photo'));
  await tester.grantCameraPermission();

  // 6. Long operation - protect against ANR
  await tester.tap(find.text('Process Data'));
  for (int i = 0; i < 10; i++) {
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.recoverFromANR();
  }

  // 7. Stop monitoring
  NativeActionHandler.instance.stopMonitoring();
});
```

---

## 🎯 Use Cases

### Use Case 1: App with Location Features

```dart
testWidgets('Test location-based feature', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Automatically grant location permission
  await tester.grantLocationPermission();

  // Now test your location feature
  await tester.tap(find.text('Find Nearby'));
  await tester.pumpAndSettle();

  expect(find.text('Results'), findsOneWidget);
});
```

---

### Use Case 2: App with Heavy Processing (ANR Risk)

```dart
testWidgets('Test heavy processing', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Start monitoring for ANR
  NativeActionHandler.instance.startMonitoring(tester);

  // Trigger heavy operation
  await tester.tap(find.text('Generate Report'));

  // Wait with ANR protection
  await tester.waitUntilResponsive(timeout: Duration(seconds: 30));

  // Verify result
  expect(find.text('Report Generated'), findsOneWidget);

  NativeActionHandler.instance.stopMonitoring();
});
```

---

### Use Case 3: Multiple Permissions

```dart
testWidgets('Test app requiring multiple permissions', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Handle all permissions at startup
  await tester.handleStartupPermissions();

  // Or grant specific permissions as needed
  await tester.tap(find.text('Enable Camera'));
  await tester.grantCameraPermission();

  await tester.tap(find.text('Enable Storage'));
  await tester.grantStoragePermission();

  await tester.tap(find.text('Enable Notifications'));
  await tester.grantNotificationPermission();

  // Test continues...
});
```

---

## 🛠️ Supported Permissions

### Location

- "Allow"
- "Allow once"
- "Allow only while using the app"
- "Allow all the time"
- "While using the app"
- "Precise location"

### Camera

- "Allow"
- "Allow camera"
- "Camera access"
- "While using the app"
- "Only this time"

### Storage/Media

- "Allow"
- "Allow storage"
- "Allow photos"
- "Allow media"
- "Allow access to photos and media"

### Notifications

- "Allow"
- "Enable notifications"
- "Turn on notifications"
- "Allow notifications"

### System Dialogs

- ANR dialogs ("App isn't responding")
- Update dialogs ("Update available")
- Battery optimization
- Crash reports
- Error dialogs

---

## ⚡ Performance Impact

The Native Action Handler is designed to be **lightweight and non-intrusive**:

- ✅ Monitoring runs every **2 seconds** (configurable)
- ✅ **Silent error catching** - won't break your tests
- ✅ **Zero impact** when no dialogs are present
- ✅ **Automatic cleanup** when monitoring stops

---

## 📊 Best Practices

### 1. Always Handle Startup Permissions

```dart
testWidgets('My test', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // ✅ DO THIS
  await tester.handleStartupPermissions();

  // ... rest of test
});
```

---

### 2. Use Background Monitoring for Long Tests

```dart
testWidgets('Long test', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // ✅ DO THIS for tests > 30 seconds
  NativeActionHandler.instance.startMonitoring(tester);

  // ... long test operations

  NativeActionHandler.instance.stopMonitoring();
});
```

---

### 3. Check for ANR After Heavy Operations

```dart
testWidgets('Test with processing', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  await tester.tap(find.text('Process'));
  await tester.pumpAndSettle(Duration(seconds: 5));

  // ✅ DO THIS after heavy operations
  await tester.recoverFromANR();

  // Continue test...
});
```

---

### 4. Grant Permissions Before Using Features

```dart
testWidgets('Test camera', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // ✅ DO THIS before tapping camera button
  await tester.grantCameraPermission();

  await tester.tap(find.text('Take Photo'));
  // ... test continues
});
```

---

## 🐛 Troubleshooting

### Issue: Permission dialog not being handled

**Solution:** Add a delay and manual grant:

```dart
await tester.tap(find.text('Enable Location'));
await tester.pumpAndSettle();
await Future.delayed(Duration(seconds: 1));
await tester.grantLocationPermission();
```

---

### Issue: ANR still causing test failure

**Solution:** Use background monitoring:

```dart
NativeActionHandler.instance.startMonitoring(tester);
// Your test code
NativeActionHandler.instance.stopMonitoring();
```

---

### Issue: Custom permission dialog not recognized

**Solution:** Use `dismissDialogs()` for custom dialogs:

```dart
await tester.tap(find.text('Custom Action'));
await tester.pumpAndSettle();
await tester.dismissDialogs(); // Handles any dialog
```

---

## 📈 Example Test Results

With Native Action Handler enabled:

```
✅ Test 1: Auto-Discovery - PASSED (handled 0 dialogs)
✅ Test 2: Navigation - PASSED (handled 0 dialogs)
✅ Test 3: Forms - PASSED (handled 0 dialogs)
✅ Test 4: Location - PASSED (handled 1 permission dialog)
✅ Test 5: Camera - PASSED (handled 1 permission dialog)
✅ Test 6: Heavy Processing - PASSED (recovered from 1 ANR)
✅ Test 7: E2E - PASSED (handled 3 dialogs, 0 ANRs)

🎯 Success Rate: 100% (7/7 tests passed)
🛡️ Native Issues Handled: 6
⚡ Total Test Time: 2m 15s
```

---

## 🎉 Summary

The Native Action Handler provides:

1. **Automatic permission handling** - No manual intervention needed
2. **ANR detection and recovery** - Tests don't fail due to timeouts
3. **Crash dialog handling** - Graceful recovery from errors
4. **Background monitoring** - Continuous protection during long tests
5. **Zero configuration** - Works out of the box
6. **Non-intrusive** - Doesn't affect test logic

**Result:** Your integration tests run smoothly without interruption from native platform issues! 🚀
