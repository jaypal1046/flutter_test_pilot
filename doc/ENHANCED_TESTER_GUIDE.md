# 🚀 Enhanced WidgetTester Extension Guide

## Overview

The Enhanced WidgetTester Extension supercharges your Flutter tests with intelligent utilities that integrate PilotFinder, SafePumpManager, and powerful testing helpers.

## 📋 Table of Contents

1. [Safe Pumping](#safe-pumping)
2. [Smart Waiting](#smart-waiting)
3. [Screen Detection](#screen-detection)
4. [Enhanced Navigation](#enhanced-navigation)
5. [Safe Gestures](#safe-gestures)
6. [Dialog & Bottom Sheet Helpers](#dialog--bottom-sheet-helpers)
7. [Error Handling](#error-handling)
8. [Performance Tracking](#performance-tracking)
9. [Complete Examples](#complete-examples)

---

## 🔄 Safe Pumping

### Replace Manual Pumps with Safe Alternatives

❌ **OLD WAY (Error-prone):**

```dart
// Manual pumping - can hang or conflict
await tester.pump();
await tester.pump(const Duration(milliseconds: 100));

// Can timeout indefinitely
await tester.pumpAndSettle();

// Manual loops
for (int i = 0; i < 20; i++) {
  await tester.pump(const Duration(milliseconds: 100));
}
```

✅ **NEW WAY (Safe & Intelligent):**

```dart
// Safe single pump with conflict detection
await tester.pumpSafe(debugLabel: 'after-login');

// Safe settle with timeout protection
await tester.pumpUntilSettled(
  timeout: const Duration(seconds: 5),
  debugLabel: 'wait-for-animations',
);

// Optimized for navigation
await tester.pumpForNavigation(debugLabel: 'to-dashboard');

// Smart pump (auto-detects animations)
await tester.pumpSmart(debugLabel: 'smart-pump');

// Multiple frames with control
await tester.pumpFrames(
  count: 10,
  interval: const Duration(milliseconds: 100),
  debugLabel: 'loading-animation',
);
```

---

## ⏱️ Smart Waiting

### Intelligent Waiting with Automatic Pumping

❌ **OLD WAY:**

```dart
// Manual waiting with manual pumping
int attempts = 0;
while (attempts < 20) {
  await tester.pump(const Duration(milliseconds: 500));
  if (tester.any(find.text('Login'))) break;
  attempts++;
}
```

✅ **NEW WAY:**

```dart
// Wait for widget to appear
final found = await tester.waitForWidget(
  tester.pilot.text('Login'),
  timeout: const Duration(seconds: 10),
  debugLabel: 'wait-login-button',
);

// Wait for widget to disappear
await tester.waitForWidgetToDisappear(
  tester.pilot.text('Loading...'),
  timeout: const Duration(seconds: 5),
);

// Wait for custom condition
await tester.waitUntil(
  () => tester.any(tester.pilot.text('Dashboard')),
  timeout: const Duration(seconds: 30),
);

// Wait with pumping
await tester.waitFor(
  const Duration(seconds: 2),
  pumpAfter: true,
  debugLabel: 'cool-down',
);
```

---

## 🖥️ Screen Detection

### Automatic Screen State Detection

```dart
// Detect current screen automatically
final screen = await tester.detectCurrentScreen();

print('Screen Type: ${screen.screenType}');
print('Widget Count: ${screen.widgetCount}');
print('Has Dialog: ${screen.hasDialog}');
print('Has Loading: ${screen.hasLoadingIndicator}');
print('Visible Texts: ${screen.visibleTexts}');

/* Output:
 * Screen Type: ScreenType.login
 * Widget Count: 42
 * Has Dialog: false
 * Has Loading: false
 * Visible Texts: [Login, Enter mobile number, Get OTP]
 */

// Check if on specific screen
final isLogin = tester.isOnScreen(
  texts: ['Login', 'Sign In'],
  keys: [Key('login_screen')],
  types: [LoginScreen],
);

// Wait for screen change
await tester.waitForScreenChange(
  timeout: const Duration(seconds: 10),
);
```

---

## 🧭 Enhanced Navigation

### Smart Navigation with Automatic Waiting

❌ **OLD WAY:**

```dart
// Manual navigation with manual pumping
await tester.tap(find.text('Login'));
await tester.pump();
await tester.pump(const Duration(milliseconds: 100));
// Hope it navigates...
await Future.delayed(const Duration(seconds: 2));
```

✅ **NEW WAY:**

```dart
// Navigate and wait for completion
await tester.navigateAndWait(
  () async {
    await tester.tap(tester.pilot.text('Login'));
  },
  timeout: const Duration(seconds: 10),
  debugLabel: 'to-dashboard',
);

// Pop and wait
await tester.popAndWait(debugLabel: 'back-to-home');
```

---

## 👆 Safe Gestures

### Gestures with Error Handling & Auto-Pumping

### 1. **Safe Tap**

```dart
// Tap with auto error handling
final success = await tester.tapSafe(
  tester.pilot.text('Submit'),
  warnOnly: true, // Don't throw, just warn
  debugLabel: 'submit-button',
);

if (!success) {
  print('Button not found, trying alternative...');
}
```

### 2. **Safe Text Entry**

```dart
// Enter text with validation
await tester.enterTextSafe(
  tester.pilot.hint('Email'),
  'test@example.com',
  debugLabel: 'email-input',
);
```

### 3. **Long Press**

```dart
// Long press with custom duration
await tester.longPressSafe(
  tester.pilot.text('Item 1'),
  duration: const Duration(seconds: 1),
  debugLabel: 'context-menu',
);
```

### 4. **Drag**

```dart
// Drag with pumping
await tester.dragSafe(
  tester.pilot.key('slider'),
  const Offset(100, 0),
  debugLabel: 'adjust-slider',
);
```

### 5. **Scroll Until Visible**

```dart
// Scroll to find widget
final found = await tester.scrollUntilVisible(
  tester.pilot.text('Item 50'),
  find.byType(ListView),
  delta: 100.0,
  maxScrolls: 50,
);

if (found) {
  await tester.tapSafe(tester.pilot.text('Item 50'));
}
```

---

## 📦 Dialog & Bottom Sheet Helpers

### Quick Getters & Dismissal Methods

```dart
// Check for UI overlays
if (tester.hasDialog) {
  print('Dialog is visible');
  await tester.dismissDialog();
}

if (tester.hasBottomSheet) {
  print('Bottom sheet is visible');
  await tester.dismissBottomSheet();
}

if (tester.hasSnackBar) {
  print('Snackbar is visible');
}
```

---

## 🐛 Error Handling & Debugging

### Automatic Error Detection

```dart
// Check for errors on screen
if (tester.hasError) {
  final errors = tester.getErrorMessages();
  print('Errors found: $errors');
}

// Capture error context for debugging
await tester.captureErrorContext('Login Test Failed');

/* Output:
 * ═══════════════════════════════════════════════════════════
 * 🔍 ERROR CONTEXT: Login Test Failed
 * ═══════════════════════════════════════════════════════════
 * Screen Type: ScreenType.login
 * Widget Count: 42
 * Has Dialog: true
 * Has Loading: false
 *
 * Visible Texts (first 10):
 *   • Login Failed
 *   • Invalid credentials
 *   • Try Again
 * ═══════════════════════════════════════════════════════════
 */
```

---

## 📊 Performance Tracking

### Monitor Test Performance

```dart
testWidgets('Login flow with performance tracking', (tester) async {
  await tester.pumpWidget(MyApp());

  // Your test code...
  await tester.tapSafe(tester.pilot.text('Login'));
  await tester.waitForWidget(tester.pilot.text('Dashboard'));

  // Print comprehensive performance stats
  tester.printPerformanceStats();

  /* Output:
   * ═══════════════════════════════════════════════════════════
   * 📊 TESTING PERFORMANCE STATISTICS
   * ═══════════════════════════════════════════════════════════
   * Safe Pump Manager:
   *   Total frames pumped: 245
   *   Successful pumps: 12
   *   Failed pumps: 0
   *   Conflicts detected: 2
   *
   * Pilot Finder:
   *   Average search: 15ms
   *   Cache hit rate: 67%
   *   Total searches: 18
   * ═══════════════════════════════════════════════════════════
   */
});

// Reset stats for next test
tester.resetPerformanceStats();
```

---

## 🎯 Complete Examples

### Example 1: Login Flow (Old vs New)

❌ **OLD WAY (Verbose & Error-prone):**

```dart
testWidgets('Login flow', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle(); // Can hang

  // Find email field
  final emailField = find.byType(TextField).first;
  await tester.enterText(emailField, 'test@example.com');
  await tester.pump();

  // Find password field
  final passwordField = find.byType(TextField).at(1);
  await tester.enterText(passwordField, 'password123');
  await tester.pump();

  // Tap login
  await tester.tap(find.text('Login'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  // Wait for navigation
  await Future.delayed(const Duration(seconds: 2));

  // Verify dashboard
  expect(find.text('Dashboard'), findsOneWidget);
});
```

✅ **NEW WAY (Clean & Reliable):**

```dart
testWidgets('Login flow', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpUntilSettled();

  // Enter credentials using PilotFinder + Safe gestures
  await tester.enterTextSafe(
    tester.pilot.hint('Email'),
    'test@example.com',
    debugLabel: 'email',
  );

  await tester.enterTextSafe(
    tester.pilot.hint('Password'),
    'password123',
    debugLabel: 'password',
  );

  // Navigate with auto-wait
  await tester.navigateAndWait(
    () => tester.tapSafe(tester.pilot.text('Login')),
    debugLabel: 'to-dashboard',
  );

  // Verify dashboard with smart detection
  final screen = await tester.detectCurrentScreen();
  expect(screen.screenType, ScreenType.dashboard);

  // Print performance
  tester.printPerformanceStats();
});
```

### Example 2: Form Filling with Error Handling

```dart
testWidgets('Registration form', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpUntilSettled();

  // Fill form with safe gestures
  final fields = {
    'First Name': 'John',
    'Last Name': 'Doe',
    'Email': 'john@example.com',
    'Phone': '1234567890',
  };

  for (final entry in fields.entries) {
    final success = await tester.enterTextSafe(
      tester.pilot.hint(entry.key),
      entry.value,
      warnOnly: true, // Don't fail if field not found
    );

    if (!success) {
      print('⚠️  Field "${entry.key}" not found, skipping...');
    }
  }

  // Submit and handle errors
  await tester.tapSafe(tester.pilot.text('Submit'));

  // Wait for either success or error
  await tester.waitFor(const Duration(seconds: 2));

  if (tester.hasError) {
    final errors = tester.getErrorMessages();
    await tester.captureErrorContext('Registration Failed');
    fail('Registration failed with errors: $errors');
  }

  // Verify success
  await tester.waitForWidget(
    tester.pilot.text('Registration Successful'),
    timeout: const Duration(seconds: 5),
  );
});
```

### Example 3: Complex Navigation Flow

```dart
testWidgets('Multi-screen navigation', (tester) async {
  await tester.pumpWidget(MyApp());

  // Screen 1: Home
  await tester.pumpUntilSettled();
  var screen = await tester.detectCurrentScreen();
  expect(screen.screenType, ScreenType.dashboard);

  // Navigate to Profile
  await tester.navigateAndWait(
    () => tester.tapSafe(tester.pilot.icon(Icons.person)),
    debugLabel: 'to-profile',
  );

  screen = await tester.detectCurrentScreen();
  expect(screen.screenType, ScreenType.profile);

  // Navigate to Settings
  await tester.navigateAndWait(
    () => tester.tapSafe(tester.pilot.text('Settings')),
    debugLabel: 'to-settings',
  );

  screen = await tester.detectCurrentScreen();
  expect(screen.screenType, ScreenType.settings);

  // Go back twice
  await tester.popAndWait(debugLabel: 'back-to-profile');
  await tester.popAndWait(debugLabel: 'back-to-home');

  // Verify we're back home
  screen = await tester.detectCurrentScreen();
  expect(screen.screenType, ScreenType.dashboard);

  // Print performance
  tester.printPerformanceStats();
});
```

### Example 4: Handling Dialogs & Bottom Sheets

```dart
testWidgets('Dialog and sheet handling', (tester) async {
  await tester.pumpWidget(MyApp());

  // Trigger dialog
  await tester.tapSafe(tester.pilot.text('Show Dialog'));
  await tester.pumpFrames(count: 5);

  // Verify and dismiss dialog
  expect(tester.hasDialog, true);

  final dismissed = await tester.dismissDialog();
  expect(dismissed, true);
  expect(tester.hasDialog, false);

  // Trigger bottom sheet
  await tester.tapSafe(tester.pilot.text('Show Options'));
  await tester.pumpFrames(count: 5);

  // Verify and dismiss sheet
  expect(tester.hasBottomSheet, true);

  await tester.dismissBottomSheet();
  expect(tester.hasBottomSheet, false);
});
```

### Example 5: Scroll and Find

```dart
testWidgets('Scroll to item', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpUntilSettled();

  // Scroll until specific item is visible
  final found = await tester.scrollUntilVisible(
    tester.pilot.text('Item 99'),
    find.byType(ListView),
    delta: 150.0,
    maxScrolls: 100,
  );

  expect(found, true);

  // Tap the item
  await tester.tapSafe(
    tester.pilot.text('Item 99'),
    debugLabel: 'select-item',
  );

  // Verify detail screen
  await tester.waitForWidget(
    tester.pilot.text('Item 99 Details'),
  );
});
```

---

## 🎓 Best Practices

### 1. **Always Use Debug Labels**

```dart
// Good: Easy to identify in logs
await tester.pumpSafe(debugLabel: 'after-login-tap');

// Bad: No context
await tester.pumpSafe();
```

### 2. **Use warnOnly for Optional Interactions**

```dart
// Optional button - don't fail test if missing
await tester.tapSafe(
  tester.pilot.text('Skip Tutorial'),
  warnOnly: true,
);
```

### 3. **Leverage Screen Detection**

```dart
// Check state before proceeding
final screen = await tester.detectCurrentScreen();

if (screen.hasLoadingIndicator) {
  await tester.waitForWidgetToDisappear(
    find.byType(CircularProgressIndicator),
  );
}
```

### 4. **Use Safe Pumping Instead of Manual Loops**

```dart
// ❌ Bad: Manual loop
for (int i = 0; i < 20; i++) {
  await tester.pump(const Duration(milliseconds: 100));
}

// ✅ Good: Safe bounded pump
await tester.pumpFrames(
  count: 20,
  interval: const Duration(milliseconds: 100),
);
```

### 5. **Track Performance Regularly**

```dart
group('Login tests', () {
  tearDown(() {
    tester.printPerformanceStats();
    tester.resetPerformanceStats();
  });

  // Tests...
});
```

---

## 📚 Summary

**The Enhanced WidgetTester Extension provides:**

✅ **Safe Pumping** - No more hangs or conflicts  
✅ **Smart Waiting** - Automatic condition checking with pumping  
✅ **Screen Detection** - Know what screen you're on automatically  
✅ **Safe Gestures** - Built-in error handling for all interactions  
✅ **Dialog Helpers** - Quick dismiss methods  
✅ **Error Context** - Automatic error capture and debugging  
✅ **Performance Tracking** - Monitor test efficiency  
✅ **PilotFinder Integration** - Best-in-class widget finding

**Start using it today to make your tests:**

- 🚀 Faster to write
- 🛡️ More reliable
- 🐛 Easier to debug
- 📊 Better tracked
- 🎯 More maintainable

🎉 **Your Flutter tests just got a major upgrade!**
