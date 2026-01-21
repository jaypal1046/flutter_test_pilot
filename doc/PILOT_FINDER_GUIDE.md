# 🔍 PilotFinder Usage Guide

## Overview

PilotFinder is a custom, intelligent widget finder for Flutter Test Pilot that extends Flutter's basic `find` with 17+ finding strategies, caching, self-healing, and performance tracking.

## 🚀 Quick Start

### Basic Usage

```dart
testWidgets('Login test with PilotFinder', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ OLD WAY (Flutter's find)
  final oldButton = find.text('Login');

  // ✅ NEW WAY (PilotFinder - smarter!)
  final smartButton = tester.pilot.text('Login');

  await tester.tap(smartButton);
});
```

## 📋 All PilotFinder Methods

### 1. **Text Finding** (with fuzzy matching)

```dart
// Exact text match
final exactMatch = tester.pilot.text('Login', exact: true);

// Fuzzy text match (default - handles typos, case differences)
final fuzzyMatch = tester.pilot.text('login'); // Finds "Login", "LOGIN", "LogIn"

// Smart find - tries ALL strategies
final smart = tester.pilot.smart('Submit Button');
```

### 2. **Key Finding**

```dart
// By any key type
final byKey = tester.pilot.key('submit_button');

// Works with ValueKey, ObjectKey, GlobalKey automatically
```

### 3. **Semantic Label Finding**

```dart
// For accessibility
final semantic = tester.pilot.semantic('Login Button');
```

### 4. **Widget Type Finding**

```dart
// By widget type
final byType = tester.pilot.type(ElevatedButton);
```

### 5. **Input Field Finding**

```dart
// By hint text (TextField)
final byHint = tester.pilot.hint('Enter email');

// By label text (TextField)
final byLabel = tester.pilot.label('Email Address');
```

### 6. **Icon Finding**

```dart
// By icon data
final byIcon = tester.pilot.icon(Icons.home);
```

### 7. **Tooltip Finding**

```dart
// By tooltip message
final byTooltip = tester.pilot.tooltip('Add to cart');
```

### 8. **Descendant/Ancestor Finding**

```dart
// Find child within parent
final child = tester.pilot.descendant(
  parent: 'Login Form',
  child: 'Email Field',
);

// Find parent containing child
final parent = tester.pilot.ancestor(
  child: 'Submit Button',
  parent: 'Form Container',
);
```

### 9. **Position-Based Finding**

```dart
// Find by index
final third = tester.pilot.atIndex(2); // 0-based index

// Find first match
final first = tester.pilot.first('Add Policy');

// Find last match
final last = tester.pilot.last('Add Policy');
```

### 10. **Custom Predicate Finding**

```dart
// Custom logic
final custom = tester.pilot.where(
  (widget) => widget is ElevatedButton && widget.enabled,
  'Enabled Button',
);
```

## 🎯 Real-World Examples

### Example 1: Login Screen

```dart
class LoginWithPilotFinder extends TestAction {
  @override
  Future<StepResult> execute(WidgetTester tester) async {
    // Find email field by hint (multiple strategies tried automatically)
    final emailField = tester.pilot.hint('Enter email');
    await tester.enterText(emailField, 'test@example.com');

    // Find password field by label
    final passwordField = tester.pilot.label('Password');
    await tester.enterText(passwordField, 'password123');

    // Smart find login button (tries text, semantic, key, etc.)
    final loginButton = tester.pilot.smart('Login');
    await tester.tap(loginButton);

    return StepResult.success(message: 'Login completed');
  }

  @override
  String get description => '🔐 Login with PilotFinder';
}
```

### Example 2: OTP Verification

```dart
class VerifyOtpWithPilot extends TestAction {
  @override
  Future<StepResult> execute(WidgetTester tester) async {
    // Check for OTP screen using fuzzy matching
    final hasOtpHeading = tester.any(tester.pilot.text('Enter OTP'));

    if (!hasOtpHeading) {
      return StepResult.failure('OTP screen not found');
    }

    // Find Pinput widget (tries multiple strategies)
    final pinput = tester.pilot.type(Pinput);
    await tester.enterText(pinput, '123456');

    // Find continue button with self-healing
    final continueBtn = tester.pilot.smart('Continue');
    await tester.tap(continueBtn);

    return StepResult.success(message: 'OTP verified');
  }

  @override
  String get description => '✅ Verify OTP with PilotFinder';
}
```

### Example 3: Dashboard Navigation

```dart
class NavigateDashboard extends TestAction {
  @override
  Future<StepResult> execute(WidgetTester tester) async {
    // Find dashboard elements with intelligent caching
    final dashboard = tester.pilot.key('dashboard_screen');

    // Find "Add Policy" button (cached after first find)
    final addPolicy = tester.pilot.text('Add Policy');
    await tester.tap(addPolicy);

    // Find within a specific section (descendant)
    final saveButton = tester.pilot.descendant(
      parent: 'Policy Form',
      child: 'Save',
    );
    await tester.tap(saveButton);

    return StepResult.success(message: 'Navigation completed');
  }

  @override
  String get description => '🏠 Navigate Dashboard';
}
```

## 📊 Performance Tracking

### View Performance Report

```dart
testWidgets('Test with performance tracking', (tester) async {
  // Run your tests...
  await tester.pumpWidget(MyApp());

  // Use PilotFinder throughout test
  final button1 = tester.pilot.text('Button 1');
  final button2 = tester.pilot.text('Button 2');
  final button3 = tester.pilot.smart('Submit');

  // Print performance report at end
  PilotFinder.printPerformanceReport();

  /* Output:
   * 📊 PILOT FINDER PERFORMANCE REPORT
   * ════════════════════════════════════════════════════════
   * 🟢 Button 1: 8ms
   * 🟢 Button 2: 5ms (cached!)
   * 🟡 Submit: 120ms
   * ────────────────────────────────────────────────────────
   * Average: 44.3ms
   * Total searches: 3
   * Cache hits: 1
   * Cache misses: 2
   * Hit rate: 33.3%
   * ════════════════════════════════════════════════════════
   */
});
```

### Clear Cache

```dart
// Clear cache when UI changes significantly
PilotFinder.clearCache();
```

## 🔧 Advanced Features

### Self-Healing

PilotFinder automatically adapts when widgets change:

```dart
// Even if button text changes from "Submit" to "submit" or "SUBMIT"
// PilotFinder will still find it using fuzzy matching
final button = tester.pilot.text('Submit'); // Finds "submit", "SUBMIT", etc.
```

### Caching for Performance

```dart
// First call: searches widget tree (slow)
final widget1 = tester.pilot.text('Login');  // 50ms

// Second call: uses cache (fast)
final widget2 = tester.pilot.text('Login');  // 2ms ⚡

// Cache automatically invalidates when widget unmounts
```

### Multiple Strategies

PilotFinder tries strategies in priority order:

1. **Key strategies** (highest priority)
2. **Exact text match**
3. **Semantic labels**
4. **Hint/Label text**
5. **Fuzzy text match**
6. **Widget type**
7. **Partial match**
8. **Deep descendant search**

## 🆚 Comparison: Flutter's find vs PilotFinder

| Feature              | `find`               | `tester.pilot`                         |
| -------------------- | -------------------- | -------------------------------------- |
| Text matching        | Exact only           | Exact + Fuzzy + Case-insensitive       |
| Caching              | ❌ No                | ✅ Yes (80%+ faster on repeated finds) |
| Self-healing         | ❌ No                | ✅ Yes (adapts to UI changes)          |
| Strategies           | 5-6 basic            | 17+ intelligent                        |
| Performance tracking | ❌ No                | ✅ Yes (detailed metrics)              |
| Error recovery       | ❌ Fails immediately | ✅ Tries multiple strategies           |
| Descendant search    | ❌ Basic             | ✅ Deep recursive search               |

## 💡 Best Practices

### 1. Use `smart()` for Flexibility

```dart
// Instead of hardcoding the exact approach
final button = tester.pilot.smart('Login');
// Tries: key → text → semantic → hint → fuzzy → etc.
```

### 2. Use Specific Methods for Performance

```dart
// If you KNOW it's a key, be specific
final byKey = tester.pilot.key('login_btn'); // Faster

// If unsure, use smart (slightly slower but more resilient)
final smart = tester.pilot.smart('login_btn');
```

### 3. Clear Cache on Major UI Changes

```dart
testWidgets('Multi-screen test', (tester) async {
  // Screen 1
  await loginFlow(tester);

  // CRITICAL: Clear cache when navigating to completely new screen
  PilotFinder.clearCache();

  // Screen 2
  await dashboardFlow(tester);
});
```

### 4. Monitor Performance

```dart
group('Performance tests', () {
  tearDown(() {
    // Print report after each test
    PilotFinder.printPerformanceReport();
  });

  testWidgets('Test 1', (tester) async {
    // Test code...
  });
});
```

## 🎉 Integration with Flutter Test Pilot

### Use in TestSuite Steps

```dart
TestSuite(
  name: 'Login Flow with PilotFinder',
  steps: [
    CustomAction(
      action: (tester) async {
        // Use PilotFinder in custom actions
        final email = tester.pilot.hint('Email');
        await tester.enterText(email, 'test@example.com');
      },
      description: 'Enter email using PilotFinder',
    ),
    // ... more steps
  ],
)
```

### Use in Custom TestActions

```dart
class MyCustomAction extends TestAction {
  @override
  Future<StepResult> execute(WidgetTester tester) async {
    // PilotFinder is available in all TestActions!
    final widget = tester.pilot.smart('My Widget');
    await tester.tap(widget);

    return StepResult.success(message: 'Action completed');
  }

  @override
  String get description => 'My custom action with PilotFinder';
}
```

## 🐛 Debugging

### Enable Verbose Logging

PilotFinder automatically logs its actions:

```
🔍 Using PilotFinder for intelligent widget detection...
✅ Cache hit for: Login (250μs)
✅ Found "Submit" using ExactText (15ms)
🔧 Self-healed "Logout" using FuzzyText (42ms)
❌ Not found: "NonExistent" after 17 strategies (320ms)
```

### Performance Report Shows Issues

```
📊 PILOT FINDER PERFORMANCE REPORT
🔴 slow_widget: 1200ms  ← Investigate this!
🟡 medium_widget: 180ms
🟢 fast_widget: 8ms
```

## 📚 Summary

**PilotFinder makes your tests:**

- ✅ **Smarter** - 17+ strategies vs 5-6 basic
- ✅ **Faster** - 80%+ improvement with caching
- ✅ **More resilient** - Self-healing adapts to changes
- ✅ **Better debugged** - Performance metrics & logging
- ✅ **Independent** - Less reliance on Flutter's basic finder

**Start using it today:**

```dart
// Replace this:
final widget = find.text('Login');

// With this:
final widget = tester.pilot.smart('Login');
```

🎯 **Your tests just got a major upgrade!**
