# TapAction Widget Support - Usage Examples

## ✨ NEW: Enhanced Widget Support

The `TapAction` class now accepts multiple types of inputs, making it incredibly flexible for tapping any widget in your Flutter tests.

## 🎯 All Available Methods

### 1. **TapAction.text()** - Tap by text
```dart
TapAction.text('Submit')
TapAction.text('Login')
```

### 2. **TapAction.key()** - Tap by key
```dart
TapAction.key('submit_button')
TapAction.key('login_form')
```

### 3. **TapAction.widget()** - Tap by text OR Finder ⭐ NEW
```dart
// By text (backward compatible)
TapAction.widget('Submit')

// By Finder - BackButton
TapAction.widget(find.byType(BackButton))

// By Finder - Icon
TapAction.widget(find.byIcon(Icons.close))

// By Finder - Widget predicate
TapAction.widget(find.byWidgetPredicate((w) => w is IconButton))

// By Finder - Ancestor
TapAction.widget(find.ancestor(
  of: find.text('Save'),
  matching: find.byType(Card),
))
```

### 4. **TapAction.byType()** - Tap by widget type ⭐ NEW
```dart
TapAction.byType(BackButton)
TapAction.byType(IconButton)
TapAction.byType(FloatingActionButton)
```

### 5. **TapAction.icon()** - Tap by icon ⭐ NEW
```dart
TapAction.icon(Icons.arrow_back)
TapAction.icon(Icons.close)
TapAction.icon(Icons.menu)
TapAction.icon(Icons.more_vert)
```

## 📝 Real-World Examples

### Example 1: Navigate Back
```dart
// Before (didn't work):
// TapAction.icon(Icons.arrow_back) ❌

// After (works perfectly):
TapAction.icon(Icons.arrow_back) ✅

// Or use:
TapAction.byType(BackButton) ✅
TapAction.widget(find.byType(BackButton)) ✅
```

### Example 2: Tap AppBar Actions
```dart
// Tap more menu icon
TapAction.icon(Icons.more_vert)

// Tap settings icon
TapAction.icon(Icons.settings)

// Tap by type
TapAction.byType(IconButton).atPosition('last')
```

### Example 3: Complex Widget Finding
```dart
// Find and tap a button inside a specific card
TapAction.widget(find.descendant(
  of: find.byKey(Key('user_card')),
  matching: find.byType(ElevatedButton),
))

// Find and tap by tooltip
TapAction.widget(find.byTooltip('Delete'))

// Find and tap by semantics
TapAction.widget(find.bySemanticsLabel('Submit Form'))
```

### Example 4: Disambiguation
```dart
// Multiple back buttons? Use position
TapAction.icon(Icons.arrow_back).atPosition('first')

// Multiple IconButtons? Use position
TapAction.byType(IconButton).atPosition('last')

// In specific context
TapAction.icon(Icons.delete).inContext('UserCard')
```

## 🔥 Complete Test Example

```dart
testWidgets('Complete navigation flow', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  final testSuite = TestSuite(
    name: 'Navigation Test',
    steps: [
      // Navigate to settings
      TapAction.icon(Icons.settings),
      Wait.forDuration(Duration(milliseconds: 500)),
      
      // Verify settings page
      VerifyWidget(finder: find.text('Settings')),
      
      // Go back using back button
      TapAction.icon(Icons.arrow_back),
      Wait.forDuration(Duration(milliseconds: 500)),
      
      // Verify we're back
      VerifyWidget(finder: find.text('Home')),
      
      // Open menu
      TapAction.icon(Icons.menu),
      Wait.forDuration(Duration(milliseconds: 500)),
      
      // Tap on a menu item by type
      TapAction.byType(ListTile).atPosition('2'),
      
      // Close dialog using close button
      TapAction.widget(find.byType(CloseButton)),
    ],
  );

  final results = await testSuite.execute(tester);
  expect(results.status, TestStatus.passed);
});
```

## �� Advanced Use Cases

### 1. Floating Action Buttons
```dart
// By type
TapAction.byType(FloatingActionButton)

// By icon
TapAction.icon(Icons.add)

// By finder with key
TapAction.widget(find.byKey(Key('fab_add')))
```

### 2. App Bar Actions
```dart
// Back button
TapAction.icon(Icons.arrow_back)

// More menu
TapAction.icon(Icons.more_vert)

// Custom icon
TapAction.icon(Icons.search)
```

### 3. Bottom Navigation
```dart
// By icon in bottom nav
TapAction.icon(Icons.home)
TapAction.icon(Icons.person)

// By position
TapAction.byType(BottomNavigationBarItem).atPosition('1')
```

### 4. Custom Widgets
```dart
// Any custom finder
TapAction.widget(find.byWidgetPredicate(
  (widget) => widget is MyCustomButton && widget.label == 'Save',
))
```

## 🚀 Migration Guide

### Old Code (Limited):
```dart
// Only worked with text
TapAction.widget('Submit')

// Couldn't tap icons - had to use workarounds
```

### New Code (Flexible):
```dart
// Text (still works)
TapAction.widget('Submit')

// Icons (now works!)
TapAction.icon(Icons.arrow_back)

// Types (new!)
TapAction.byType(BackButton)

// Finders (new!)
TapAction.widget(find.byType(BackButton))
TapAction.widget(find.byIcon(Icons.close))
TapAction.widget(find.byTooltip('Delete'))
```

## ✅ Benefits

1. **Backward Compatible**: All existing tests continue to work
2. **Flexible**: Accept String, Finder, Type, or IconData
3. **Type Safe**: Proper error handling for invalid types
4. **Comprehensive**: Can tap ANY widget in your Flutter app
5. **Intuitive API**: Method names clearly indicate what they do

## 📚 See Also

- `Type` class for text input strategies
- `Scroll` class for scrolling actions
- `VerifyWidget` for widget assertions
- `Wait` for timing conditions
