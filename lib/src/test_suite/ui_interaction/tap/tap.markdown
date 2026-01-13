# Using the `Tap` Class for Widget Interaction in Flutter Tests

The `Tap` class and its related gesture classes (`DoubleTap`, `TripleTap`, and `LongPress`) enable a variety of tap interactions in Flutter widget tests. In addition to single taps, you can perform double taps, triple taps, and long presses on widgets using similar strategies for finding and disambiguating targets.

Supported gesture classes:

- **Tap**: Single tap (default).
- **DoubleTap**: Double tap gesture.
- **TripleTap**: Triple tap gesture.
- **LongPress**: Long press gesture.

Each gesture class supports the same finding strategies:
- By key: `.key('key')`
- By text: `.text('text')`
- By widget text: `.widget('text')`

**Usage Example:**
```dart
final doubleTapAction = DoubleTap.text('Submit');
final tripleTapAction = TripleTap.key('submit_button');
final longPressAction = LongPress.widget('Login');

// Execute the gesture
await doubleTapAction.execute(tester);
await tripleTapAction.execute(tester);
await longPressAction.execute(tester);
```

Disambiguation options (`inContext`, `atPosition`) work identically for all gesture types.

This document covers all finding strategies and gesture types, with setup, test examples, and disambiguation options.

## Prerequisites for All Examples

In your test file, set up the following:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart'; // For Material widgets
import '../../../../../test/lib/src/test_suite/ui_interaction/tap/path_to_your_tap_class.dart'; // e.g., 'package:your_test_actions/tap.dart'
import '../../../../../test/lib/src/test_suite/ui_interaction/tap/main.dart'; // Your app entry point

void main() {
  testWidgets('Test Tap class strategies', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp()); // Pump your app/widget tree
    // Examples below go here
  });
}
```

Ensure your `MyApp` widget contains the tappable widgets (e.g., buttons, icons) you want to test.

---

## Finding and Tapping Strategies

The `Tap` class supports three strategies for locating widgets:
1. **By Key**: Uses a `Key` (e.g., `ValueKey`, `Key`) to find a widget.
2. **By Text**: Matches a widget containing specific text (e.g., a `Text` widget or button label).
3. **By Widget Type**: Finds a widget by its type (e.g., `ElevatedButton`, `IconButton`).

If multiple widgets match, you can disambiguate using:
- `inContext(String)`: Specifies a context description (currently defaults to the first match; extend `_disambiguateFinder` for advanced use).
- `atPosition(String)`: Selects a widget by position (`'first'`, `'last'`, or an index like `'0'`).

Below, each strategy is detailed with a widget setup, test example, and disambiguation options.

---

### 1. Tapping by Key (`Tap.key`)

**Description**: Locates a widget using a `Key` (e.g., `ValueKey`, `Key`). This is the most direct and performant method, as keys are typically unique. The `Tap` class uses `find.byKey` to locate the widget.

**Widget Setup**:
```dart
ElevatedButton(
  key: ValueKey('submit_button'),
  onPressed: () {},
  child: Text('Submit'),
),
```

**Test Example**:
```dart
final tapAction = Tap.key('submit_button');
final result = await tapAction.execute(tester);
expect(result.isSuccess, true);
expect(result.message, contains('Tapped submit_button'));
```

**Disambiguation**:
- Keys are usually unique, so disambiguation is rarely needed.
- If multiple widgets have the same key (unlikely), use `atPosition`:
  ```dart
  final tapAction = Tap.key('submit_button').atPosition('first');
  final result = await tapAction.execute(tester);
  expect(result.isSuccess, true);
  ```
- `inContext` can be used but requires extending `_disambiguateFinder` to check ancestor properties.

---

### 2. Tapping by Text (`Tap.text` or `Tap.widget`)

**Description**: Finds a widget containing the specified text using `find.text`. This is useful for buttons, labels, or other widgets with text content. If multiple widgets match, you must disambiguate with `inContext` or `atPosition`, or the test fails with an error.

**Widget Setup**:
```dart
Column(
  children: [
    ElevatedButton(
      onPressed: () {},
      child: Text('Login'), // First Login button
    ),
    ElevatedButton(
      onPressed: () {},
      child: Text('Login'), // Second Login button
    ),
  ],
),
```

**Test Example (Single Match)**:
```dart
// Assuming only one "Submit" button exists
final tapAction = Tap.text('Submit');
final result = await tapAction.execute(tester);
expect(result.isSuccess, true);
expect(result.message, contains('Tapped Submit'));
```

**Test Example (Disambiguation with Multiple Matches)**:
```dart
// Tap the first "Login" button
final tapAction = Tap.text('Login').atPosition('first');
final result = await tapAction.execute(tester);
expect(result.isSuccess, true);
expect(result.message, contains('Tapped Login'));

// Tap the second "Login" button
final tapAction2 = Tap.text('Login').atPosition('1');
final result2 = await tapAction2.execute(tester);
expect(result2.isSuccess, true);
expect(result2.message, contains('Tapped Login'));
```

**Disambiguation**:
- Without disambiguation, multiple matches throw an error like:
  ```
  Found 2 widgets with text "Login". Use .inContext("description") or .atPosition("first|last") to disambiguate.
  ```
- `atPosition('first')`, `atPosition('last')`, or `atPosition('N')` (where `N` is an index) resolves multiple matches.
- `inContext` currently defaults to the first match. To enhance it, modify `_disambiguateFinder` to check ancestor widgets (e.g., parent `Container` or `Form` properties).

---

### 3. Tapping by Widget Type (`Tap` with `widgetType`)

**Description**: Finds a widget by its type using `find.byType`. This is useful for tapping widgets without text or keys, such as `IconButton` or `FloatingActionButton`. Disambiguation is needed if multiple instances exist.

**Widget Setup**:
```dart
IconButton(
  icon: Icon(Icons.search),
  onPressed: () {},
),
```

**Test Example**:
```dart
final tapAction = Tap._(widgetType: IconButton);
final result = await tapAction.execute(tester);
expect(result.isSuccess, true);
expect(result.message, contains('Tapped IconButton'));
```

**Disambiguation**:
- If multiple widgets of the same type exist, use `atPosition`:
  ```dart
  final tapAction = Tap._(widgetType: IconButton).atPosition('first');
  final result = await tapAction.execute(tester);
  expect(result.isSuccess, true);
  ```
- `inContext` can be used but requires extending `_disambiguateFinder` for context-based filtering.

---

## General Notes on Tapping Behaviors

- **Execution**: The `execute` method uses `tester.tap(finder)` to tap the widget and calls `pumpAndSettle` to update the UI. Always await `execute` in tests.
- **Return Value**: Returns a `StepResult` with:
  - `isSuccess`: `true` if the tap succeeds, `false` if it fails (e.g., widget not found or multiple matches without disambiguation).
  - `message`: Describes the action (e.g., `Tapped Submit`) or error details.
  - `duration`: Time taken for the operation, measured using a `Stopwatch`.
- **Disambiguation**:
  - Use `atPosition('first')`, `atPosition('last')`, or `atPosition('N')` to select a specific widget when multiple matches are found.
  - `inContext` is currently limited (defaults to the first match). Enhance `_disambiguateFinder` to check ancestor properties, similar to the `Type` class’s parent/child searches.
- **Error Handling**: If no widget is found, or if multiple matches occur without disambiguation, a `StepResult.failure` is returned with a descriptive error message.
- **Verification**: After tapping, verify the outcome by checking the app’s state (e.g., a new widget appears, or a callback updates a value):
  ```dart
  final tapAction = Tap.text('Submit');
  await tapAction.execute(tester);
  expect(find.text('Success Message'), findsOneWidget); // Verify UI change
  ```
- **Edge Cases**: Test for failure cases (e.g., non-existent widgets) to ensure robust tests:
  ```dart
  final tapAction = Tap.text('NonExistent');
  final result = await tapAction.execute(tester);
  expect(result.isSuccess, false);
  ```

## Enhancing the `Tap` Class (Optional)

The current `Tap` class has a basic `_disambiguateFinder` method. To make `inContext` more powerful, similar to the `Type` class’s advanced strategies (e.g., parent properties), you can extend `_disambiguateFinder`:

```dart
Finder _disambiguateFinder(Finder finder, WidgetTester tester) {
  if (context?.contextDescription != null) {
    final candidates = tester.widgetList(finder);
    for (final widget in candidates) {
      final element = tester.element(find.byWidget(widget));
      final parent = element.findAncestorWidgetOfExactType<Widget>();
      if (parent != null && parent.toString().contains(context!.contextDescription!)) {
        return find.byWidget(widget);
      }
    }
  }
  if (context?.position != null) {
    switch (context!.position!) {
      case 'first':
        return finder.first;
      case 'last':
        return finder.last;
      default:
        final index = int.tryParse(context!.position!);
        if (index != null) {
          return finder.at(index);
        }
    }
  }
  return finder.first;
}
```

This allows `inContext` to match widgets based on ancestor properties, improving disambiguation for complex widget trees.

## Example: Full Test Suite

Here’s a complete test suite demonstrating all strategies, assuming a widget tree with multiple tappable elements.

**Widget Setup in `main.dart`**:
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              key: ValueKey('submit_button'),
              onPressed: () {},
              child: Text('Submit'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Login'), // First Login button
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Login'), // Second Login button
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
```

**Test Code**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../../../../test/lib/src/test_suite/ui_interaction/tap/path_to_your_tap_class.dart'; // Adjust path
import '../../../../../test/lib/src/test_suite/ui_interaction/tap/main.dart';

void main() {
  testWidgets('Test all Tap strategies', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // 1. Tap by key
    var tapAction = Tap.key('submit_button');
    var result = await tapAction.execute(tester);
    expect(result.isSuccess, true);
    expect(result.message, contains('Tapped submit_button'));

    // 2. Tap by text (first Login button)
    tapAction = Tap.text('Login').atPosition('first');
    result = await tapAction.execute(tester);
    expect(result.isSuccess, true);
    expect(result.message, contains('Tapped Login'));

    // 3. Tap by text (second Login button)
    tapAction = Tap.text('Login').atPosition('1');
    result = await tapAction.execute(tester);
    expect(result.isSuccess, true);
    expect(result.message, contains('Tapped Login'));

    // 4. Tap by widget type
    tapAction = Tap._(widgetType: IconButton);
    result = await tapAction.execute(tester);
    expect(result.isSuccess, true);
    expect(result.message, contains('Tapped IconButton'));

    // 5. Test failure case (non-existent text)
    tapAction = Tap.text('NonExistent');
    result = await tapAction.execute(tester);
    expect(result.isSuccess, false);
    expect(result.message, contains('Tap failed'));

    // 6. Test multiple matches without disambiguation (should fail)
    tapAction = Tap.text('Login');
    result = await tapAction.execute(tester);
    expect(result.isSuccess, false);
    expect(result.message, contains('Found 2 widgets with text "Login"'));
  });
}
```

## Comparison with `Type` Class

The `Tap` class shares similarities with the `Type` class (used for text input):
- Both use `Finder` to locate widgets.
- Both return a `StepResult` for test feedback.
- Both support disambiguation for multiple matches.
- Both integrate with `WidgetTester` for UI interaction.

However, `Tap` is simpler, with only three finding strategies compared to `Type`’s 17. You can extend `Tap` to include more strategies (e.g., semantics, tooltip, or parent properties) by following the `Type` class’s approach.

## Conclusion

The `Tap` class is a robust tool for tapping widgets in Flutter widget tests. Use `Tap.key` for precise targeting, `Tap.text` for text-based widgets, and `Tap._(widgetType: ...)` for type-based selection. Disambiguate multiple matches with `atPosition` or enhance `inContext` for complex scenarios. For further customization or additional test cases, refer to the `Type` class’s advanced strategies or let me know your specific needs!