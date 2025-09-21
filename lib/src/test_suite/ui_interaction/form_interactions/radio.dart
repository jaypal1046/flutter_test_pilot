import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../step_result.dart';
import '../../test_action.dart';
import '../advanced_gestures/scroll.dart';

/// Radio button interaction action that uses tap and scroll gestures
class RadioAction extends TestAction {
  final String? radioKey;
  final String? radioText;
  final String? radioLabel;
  final dynamic radioValue;
  final Type? radioType;
  final RadioOperation operation;
  final RadioContext? context;
  final Duration searchTimeout;
  final int maxScrollAttempts;
  final bool strictMode;

  const RadioAction._({
    this.radioKey,
    this.radioText,
    this.radioLabel,
    this.radioValue,
    this.radioType,
    required this.operation,
    this.context,
    this.searchTimeout = const Duration(seconds: 10),
    this.maxScrollAttempts = 20,
    this.strictMode = false,
  });

  /// Select a radio button by key
  factory RadioAction.selectByKey(
    String radioKey, {
    RadioContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return RadioAction._(
      radioKey: radioKey,
      operation: RadioOperation.select,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Select a radio button by label text
  factory RadioAction.selectByLabel(
    String labelText, {
    RadioContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return RadioAction._(
      radioLabel: labelText,
      operation: RadioOperation.select,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Select a radio button by value
  factory RadioAction.selectByValue(
    dynamic value, {
    RadioContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return RadioAction._(
      radioValue: value,
      operation: RadioOperation.select,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Verify radio button selection state
  factory RadioAction.verifySelected(
    String identifier, {
    bool byKey = false,
    bool byValue = false,
    RadioContext? context,
  }) {
    if (byValue) {
      return RadioAction._(
        radioValue: identifier,
        operation: RadioOperation.verifySelected,
        context: context,
      );
    } else if (byKey) {
      return RadioAction._(
        radioKey: identifier,
        operation: RadioOperation.verifySelected,
        context: context,
      );
    } else {
      return RadioAction._(
        radioLabel: identifier,
        operation: RadioOperation.verifySelected,
        context: context,
      );
    }
  }

  /// Verify radio button is not selected
  factory RadioAction.verifyNotSelected(
    String identifier, {
    bool byKey = false,
    bool byValue = false,
    RadioContext? context,
  }) {
    if (byValue) {
      return RadioAction._(
        radioValue: identifier,
        operation: RadioOperation.verifyNotSelected,
        context: context,
      );
    } else if (byKey) {
      return RadioAction._(
        radioKey: identifier,
        operation: RadioOperation.verifyNotSelected,
        context: context,
      );
    } else {
      return RadioAction._(
        radioLabel: identifier,
        operation: RadioOperation.verifyNotSelected,
        context: context,
      );
    }
  }

  /// Add context for disambiguation
  RadioAction inContext(String contextDescription) {
    return RadioAction._(
      radioKey: radioKey,
      radioText: radioText,
      radioLabel: radioLabel,
      radioValue: radioValue,
      radioType: radioType,
      operation: operation,
      context: RadioContext._(
        contextDescription: contextDescription,
        position: context?.position,
        groupName: context?.groupName,
        groupValue: context?.groupValue,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      strictMode: strictMode,
    );
  }

  /// Specify position for disambiguation
  RadioAction atPosition(String position) {
    return RadioAction._(
      radioKey: radioKey,
      radioText: radioText,
      radioLabel: radioLabel,
      radioValue: radioValue,
      radioType: radioType,
      operation: operation,
      context: RadioContext._(
        contextDescription: context?.contextDescription,
        position: position,
        groupName: context?.groupName,
        groupValue: context?.groupValue,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      strictMode: strictMode,
    );
  }

  /// Specify radio button group
  RadioAction inGroup(String groupName) {
    return RadioAction._(
      radioKey: radioKey,
      radioText: radioText,
      radioLabel: radioLabel,
      radioValue: radioValue,
      radioType: radioType,
      operation: operation,
      context: RadioContext._(
        contextDescription: context?.contextDescription,
        position: context?.position,
        groupName: groupName,
        groupValue: context?.groupValue,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      strictMode: strictMode,
    );
  }

  /// Specify the group's current value (for verification)
  RadioAction withGroupValue(dynamic groupValue) {
    return RadioAction._(
      radioKey: radioKey,
      radioText: radioText,
      radioLabel: radioLabel,
      radioValue: radioValue,
      radioType: radioType,
      operation: operation,
      context: RadioContext._(
        contextDescription: context?.contextDescription,
        position: context?.position,
        groupName: context?.groupName,
        groupValue: groupValue,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      strictMode: strictMode,
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Find the radio button
      final radioFinder = await _findRadioButton(tester);

      // Perform the operation
      await _performOperation(tester, radioFinder);

      // Wait for UI to settle
      await tester.pumpAndSettle();

      stopwatch.stop();

      return StepResult.success(
        message: _getSuccessMessage(),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Radio button ${operation.name} failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<Finder> _findRadioButton(WidgetTester tester) async {
    final endTime = DateTime.now().add(searchTimeout);
    var scrollAttempts = 0;

    while (DateTime.now().isBefore(endTime) &&
        scrollAttempts < maxScrollAttempts) {
      Finder? radioFinder;

      // Try different methods to find the radio button
      if (radioKey != null) {
        radioFinder = find.byKey(Key(radioKey!));
      } else if (radioLabel != null) {
        radioFinder = _findRadioByLabel(tester);
      } else if (radioValue != null) {
        radioFinder = _findRadioByValue(tester);
      } else if (radioText != null) {
        radioFinder = find.text(radioText!);
      } else if (radioType != null) {
        radioFinder = find.byType(radioType!);
      }

      if (radioFinder != null && tester.widgetList(radioFinder).isNotEmpty) {
        return _disambiguateRadio(radioFinder, tester);
      }

      // Radio button not found, scroll to find it
      await _scrollToFindRadio(tester);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      scrollAttempts++;
    }

    throw Exception('Radio button not found: ${_getRadioIdentifier()}');
  }

  Finder _findRadioByLabel(WidgetTester tester) {
    // Look for radio button with associated label
    final radios = find.byType(Radio);
    final radioTiles = find.byType(RadioListTile);

    // Try RadioListTile first (has built-in label)
    for (final tile in tester.widgetList(radioTiles)) {
      final radioListTile = tile as RadioListTile;
      if (radioListTile.title != null) {
        final titleWidget = radioListTile.title!;
        if (titleWidget is Text && titleWidget.data == radioLabel) {
          return find.byWidget(tile);
        }
      }
    }

    // Look for text near radio widgets
    final labelFinder = find.text(radioLabel!);
    if (tester.widgetList(labelFinder).isNotEmpty) {
      // Find radio button near the label
      for (final radio in tester.widgetList(radios)) {
        final radioWidget = tester.getRect(find.byWidget(radio));
        final labelWidget = tester.getRect(labelFinder.first);

        // Check if radio and label are close to each other
        final distance = (radioWidget.center - labelWidget.center).distance;
        if (distance < 100) {
          // Adjust threshold as needed
          return find.byWidget(radio);
        }
      }

      // Fallback: tap on the label itself (might trigger radio)
      return labelFinder.first;
    }

    throw Exception('Radio button with label "$radioLabel" not found');
  }

  Finder _findRadioByValue(WidgetTester tester) {
    // For Radio widgets
    final radioFinder = find.byWidgetPredicate((widget) {
      if (widget is Radio) {
        // This approach tries to access the value through widget properties
        try {
          return widget.toString().contains('value: $radioValue');
        } catch (e) {
          return false;
        }
      }
      return false;
    });

    if (tester.widgetList(radioFinder).isNotEmpty) {
      return radioFinder.first;
    }

    // For RadioListTile widgets
    final radioTileFinder = find.byWidgetPredicate((widget) {
      if (widget is RadioListTile) {
        try {
          return widget.value == radioValue;
        } catch (e) {
          return false;
        }
      }
      return false;
    });

    if (tester.widgetList(radioTileFinder).isNotEmpty) {
      return radioTileFinder.first;
    }

    throw Exception('Radio button with value "$radioValue" not found');
  }

  Finder _disambiguateRadio(Finder finder, WidgetTester tester) {
    final widgets = tester.widgetList(finder);

    if (widgets.length == 1) {
      return finder.first;
    }

    // Multiple radio buttons found, use context to disambiguate
    if (context?.position != null) {
      switch (context!.position!.toLowerCase()) {
        case 'first':
          return finder.first;
        case 'last':
          return finder.last;
        default:
          final index = int.tryParse(context!.position!);
          if (index != null && index < widgets.length) {
            return finder.at(index);
          }
          throw Exception(
            'Invalid position "${context!.position}" for radio button. '
            'Use "first", "last", or a valid index.',
          );
      }
    }

    if (context?.contextDescription != null) {
      // Find radio button within specific context/ancestor
      final contextFinder = find.ancestor(
        of: finder,
        matching: find.byWidgetPredicate(
          (widget) => widget.toString().toLowerCase().contains(
            context!.contextDescription!.toLowerCase(),
          ),
        ),
      );
      if (tester.widgetList(contextFinder).isNotEmpty) {
        return contextFinder.first;
      }
    }

    if (context?.groupName != null) {
      // Look for radio buttons in a specific group/form section
      final groupFinder = find.text(context!.groupName!);
      if (tester.widgetList(groupFinder).isNotEmpty) {
        final groupRect = tester.getRect(groupFinder.first);

        // Find radio buttons near the group title
        for (int i = 0; i < widgets.length; i++) {
          final radioRect = tester.getRect(finder.at(i));
          if ((radioRect.center - groupRect.center).distance < 300) {
            return finder.at(i);
          }
        }
      }
    }

    throw Exception('''
Found ${widgets.length} radio buttons matching criteria.
Use .inContext("description"), .atPosition("first|last|index"), or .inGroup("group name") to disambiguate:

Example: RadioAction.selectByLabel("Option A").inContext("Payment Method")
         RadioAction.selectByKey("gender_male").atPosition("first")
         RadioAction.selectByValue("credit_card").inGroup("Payment Options")
''');
  }

  Future<void> _performOperation(
    WidgetTester tester,
    Finder radioFinder,
  ) async {
    final currentState = _getRadioState(tester, radioFinder);

    switch (operation) {
      case RadioOperation.select:
        if (!currentState) {
          await _tapRadio(tester, radioFinder);
        } else if (strictMode) {
          throw Exception('Radio button is already selected');
        }
        break;

      case RadioOperation.verifySelected:
        if (!currentState) {
          throw Exception(
            'Expected radio button to be selected, but it was not selected',
          );
        }
        break;

      case RadioOperation.verifyNotSelected:
        if (currentState) {
          throw Exception(
            'Expected radio button to not be selected, but it was selected',
          );
        }
        break;
    }
  }

  Future<void> _tapRadio(WidgetTester tester, Finder radioFinder) async {
    await tester.tap(radioFinder);
    await tester.pump(const Duration(milliseconds: 100));
  }

  bool _getRadioState(WidgetTester tester, Finder radioFinder) {
    final widget = tester.widget(radioFinder);

    // Method 1: Handle Radio widgets
    if (widget is Radio) {
      return _getRadioWidgetState(tester, radioFinder, widget);
    }
    // Method 2: Handle RadioListTile widgets
    else if (widget is RadioListTile) {
      return _getRadioListTileState(tester, radioFinder, widget);
    }
    // Method 3: Handle custom radio widgets
    else {
      return _getCustomRadioState(tester, radioFinder);
    }
  }

  /// Get state for standard Radio widgets
  bool _getRadioWidgetState(
    WidgetTester tester,
    Finder radioFinder,
    Widget widget,
  ) {
    // Strategy 1: Try to access properties via reflection or toString analysis
    try {
      final widgetString = widget.toString();

      // Parse the widget string to extract groupValue and value
      // Radio widgets toString typically shows: "Radio<Type>(value: X, groupValue: Y, ...)"
      final valueMatch = RegExp(r'value:\s*([^,\)]+)').firstMatch(widgetString);
      final groupValueMatch = RegExp(
        r'groupValue:\s*([^,\)]+)',
      ).firstMatch(widgetString);

      if (valueMatch != null && groupValueMatch != null) {
        final value = valueMatch.group(1)?.trim();
        final groupValue = groupValueMatch.group(1)?.trim();

        // Compare the string representations
        return value == groupValue && value != 'null';
      }
    } catch (e) {
      // Fall through to other methods
    }

    // Strategy 2: Use semantics if available
    try {
      final element = tester.element(radioFinder);
      if (element.renderObject != null) {
        final renderObject = element.renderObject!;

        // Check if render object has selection state in its debug info
        final debugString = renderObject.toStringDeep();
        if (debugString.contains('selected: true') ||
            debugString.contains('checked: true') ||
            debugString.contains('isSelected: true')) {
          return true;
        }
        if (debugString.contains('selected: false') ||
            debugString.contains('checked: false') ||
            debugString.contains('isSelected: false')) {
          return false;
        }
      }
    } catch (e) {
      // Continue to visual inspection
    }

    // Strategy 3: Visual inspection - look for selection indicators
    return _hasVisualSelectionIndicators(tester, radioFinder);
  }

  /// Get state for RadioListTile widgets
  bool _getRadioListTileState(
    WidgetTester tester,
    Finder radioFinder,
    RadioListTile widget,
  ) {
    // Strategy 1: Try toString analysis (more reliable for RadioListTile)
    try {
      final widgetString = widget.toString();

      // RadioListTile toString shows more detailed info
      final valueMatch = RegExp(r'value:\s*([^,\)]+)').firstMatch(widgetString);
      final groupValueMatch = RegExp(
        r'groupValue:\s*([^,\)]+)',
      ).firstMatch(widgetString);
      final selectedMatch = RegExp(
        r'selected:\s*(true|false)',
      ).firstMatch(widgetString);

      // First check explicit 'selected' property if available
      if (selectedMatch != null) {
        return selectedMatch.group(1) == 'true';
      }

      // Then compare value and groupValue
      if (valueMatch != null && groupValueMatch != null) {
        final value = valueMatch.group(1)?.trim();
        final groupValue = groupValueMatch.group(1)?.trim();
        return value == groupValue && value != 'null';
      }
    } catch (e) {
      // Fall through to other methods
    }

    // Strategy 2: Check for ListTile selection visual indicators
    try {
      // RadioListTile often has a leading radio widget
      final radioWidget = find.descendant(
        of: radioFinder,
        matching: find.byType(Radio),
      );

      if (tester.widgetList(radioWidget).isNotEmpty) {
        final radio = tester.widget(radioWidget);
        return _getRadioWidgetState(tester, radioWidget, radio);
      }
    } catch (e) {
      // Continue to visual inspection
    }

    // Strategy 3: Visual inspection
    return _hasVisualSelectionIndicators(tester, radioFinder);
  }

  /// Get state for custom radio widgets
  bool _getCustomRadioState(WidgetTester tester, Finder radioFinder) {
    // Strategy 1: Look for standard selection patterns in widget tree
    final selectionPatterns = [
      'selected',
      'checked',
      'active',
      'chosen',
      'picked',
      'current',
    ];

    for (final pattern in selectionPatterns) {
      try {
        final selectedFinder = find.descendant(
          of: radioFinder,
          matching: find.byWidgetPredicate((w) {
            final widgetString = w.toString().toLowerCase();
            final typeString = w.runtimeType.toString().toLowerCase();
            return widgetString.contains(pattern) ||
                typeString.contains(pattern);
          }),
        );

        if (tester.widgetList(selectedFinder).isNotEmpty) {
          return true;
        }
      } catch (e) {
        // Continue with next pattern
      }
    }

    // Strategy 2: Look for visual state indicators
    return _hasVisualSelectionIndicators(tester, radioFinder);
  }

  /// Check for visual selection indicators (common helper method)
  bool _hasVisualSelectionIndicators(WidgetTester tester, Finder radioFinder) {
    try {
      // Look for common visual selection indicators
      final visualIndicators = [
        // Look for filled circles, dots, or selection markers
        find.descendant(
          of: radioFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w.runtimeType.toString().contains('Circle') ||
                w.runtimeType.toString().contains('Dot') ||
                w.runtimeType.toString().contains('Icon'),
          ),
        ),

        // Look for containers with decorations (often used for selection)
        find.descendant(
          of: radioFinder,
          matching: find.byWidgetPredicate((w) {
            if (w is Container && w.decoration != null) {
              final decorationString = w.decoration.toString();
              return decorationString.contains('color') ||
                  decorationString.contains('border');
            }
            return false;
          }),
        ),

        // Look for opacity or theme changes that might indicate selection
        find.descendant(
          of: radioFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Opacity && (w.opacity > 0.8) ||
                w.runtimeType.toString().contains('Theme') ||
                w.runtimeType.toString().contains('Material'),
          ),
        ),
      ];

      // If we find any visual indicators, assume selected state
      // This is heuristic but often works for custom implementations
      for (final indicator in visualIndicators) {
        if (tester.widgetList(indicator).isNotEmpty) {
          return true;
        }
      }
    } catch (e) {
      // Visual inspection failed
    }

    // Strategy 3: Check render object for visual state
    try {
      final element = tester.element(radioFinder);
      if (element.renderObject != null) {
        final renderObject = element.renderObject!;

        // Look for paint properties that might indicate selection
        final debugString = renderObject.toStringDeep().toLowerCase();
        return debugString.contains('fill') ||
            debugString.contains('solid') ||
            debugString.contains('opacity: 1.0') ||
            (debugString.contains('color') &&
                !debugString.contains('transparent'));
      }
    } catch (e) {
      // Render object inspection failed
    }

    // Default to false if we can't determine state
    return false;
  }

  Future<void> _scrollToFindRadio(WidgetTester tester) async {
    try {
      final scroll = Scroll.down(distance: 200);
      await scroll.execute(tester);
    } catch (e) {
      // If scrolling fails, try scrolling up
      try {
        final scroll = Scroll.up(distance: 200);
        await scroll.execute(tester);
      } catch (e) {
        // Ignore scroll errors, continue searching
      }
    }
  }

  String _getRadioIdentifier() {
    return radioKey ??
        radioLabel ??
        radioValue?.toString() ??
        radioText ??
        radioType?.toString() ??
        'unknown';
  }

  String _getSuccessMessage() {
    final identifier = _getRadioIdentifier();
    switch (operation) {
      case RadioOperation.select:
        return 'Selected radio button: $identifier';
      case RadioOperation.verifySelected:
        return 'Verified radio button is selected: $identifier';
      case RadioOperation.verifyNotSelected:
        return 'Verified radio button is not selected: $identifier';
    }
  }

  @override
  String get description =>
      '${operation.name} radio button: ${_getRadioIdentifier()}';
}

enum RadioOperation { select, verifySelected, verifyNotSelected }

class RadioContext {
  final String? contextDescription;
  final String? position;
  final String? groupName;
  final dynamic groupValue;

  const RadioContext._({
    this.contextDescription,
    this.position,
    this.groupName,
    this.groupValue,
  });
}

/// Convenience class for common radio operations
class Radio {
  /// Select a radio button
  static RadioAction select(
    String identifier, {
    bool byKey = false,
    bool byValue = false,
    RadioContext? context,
  }) {
    if (byValue) {
      return RadioAction.selectByValue(identifier, context: context);
    } else if (byKey) {
      return RadioAction.selectByKey(identifier, context: context);
    } else {
      return RadioAction.selectByLabel(identifier, context: context);
    }
  }

  /// Verify radio button is selected
  static RadioAction verifySelected(
    String identifier, {
    bool byKey = false,
    bool byValue = false,
  }) {
    return RadioAction.verifySelected(
      identifier,
      byKey: byKey,
      byValue: byValue,
    );
  }

  /// Verify radio button is not selected
  static RadioAction verifyNotSelected(
    String identifier, {
    bool byKey = false,
    bool byValue = false,
  }) {
    return RadioAction.verifyNotSelected(
      identifier,
      byKey: byKey,
      byValue: byValue,
    );
  }
}

/// Extended radio actions for complex scenarios
class RadioActions {
  /// Select radio option from a group and verify others are deselected
  static Future<StepResult> selectInGroup(
    WidgetTester tester,
    String groupName,
    String optionToSelect, {
    List<String>? otherOptions,
    bool byKey = false,
    bool byValue = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Select the target option
      final selectAction = byValue
          ? RadioAction.selectByValue(optionToSelect).inGroup(groupName)
          : byKey
          ? RadioAction.selectByKey(optionToSelect).inGroup(groupName)
          : RadioAction.selectByLabel(optionToSelect).inGroup(groupName);

      await selectAction.execute(tester);

      // Verify other options are deselected (if provided)
      if (otherOptions != null) {
        for (final option in otherOptions) {
          final verifyAction = RadioAction.verifyNotSelected(
            option,
            byKey: byKey,
            byValue: byValue,
          ).inGroup(groupName);

          final result = await verifyAction.execute(tester);
          if (!result.success) {
            throw Exception(
              'Option $option should be deselected but is still selected',
            );
          }
        }
      }

      stopwatch.stop();
      return StepResult.success(
        message: 'Selected "$optionToSelect" in group "$groupName"',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Group selection failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Get currently selected option in a radio group
  static Future<String?> getSelectedOption(
    WidgetTester tester,
    List<String> options, {
    String? groupName,
    bool byKey = false,
    bool byValue = false,
  }) async {
    for (final option in options) {
      try {
        final action = RadioAction.verifySelected(
          option,
          byKey: byKey,
          byValue: byValue,
        );
        final actionWithGroup = groupName != null
            ? action.inGroup(groupName)
            : action;
        final radioFinder = await actionWithGroup._findRadioButton(tester);
        final isSelected = actionWithGroup._getRadioState(tester, radioFinder);

        if (isSelected) {
          return option;
        }
      } catch (e) {
        // Continue checking other options
      }
    }

    return null; // No option is selected
  }

  /// Verify exactly one option is selected in a group
  static Future<StepResult> verifyExclusiveSelection(
    WidgetTester tester,
    List<String> options,
    String expectedSelected, {
    String? groupName,
    bool byKey = false,
    bool byValue = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      var selectedCount = 0;
      String? actualSelected;

      for (final option in options) {
        try {
          final action = RadioAction.verifySelected(
            option,
            byKey: byKey,
            byValue: byValue,
          );
          final actionWithGroup = groupName != null
              ? action.inGroup(groupName)
              : action;
          final radioFinder = await actionWithGroup._findRadioButton(tester);
          final isSelected = actionWithGroup._getRadioState(
            tester,
            radioFinder,
          );

          if (isSelected) {
            selectedCount++;
            actualSelected = option;
          }
        } catch (e) {
          // Continue checking other options
        }
      }

      if (selectedCount == 0) {
        throw Exception('No radio button is selected in the group');
      } else if (selectedCount > 1) {
        throw Exception(
          'Multiple radio buttons are selected (found $selectedCount)',
        );
      } else if (actualSelected != expectedSelected) {
        throw Exception(
          'Expected "$expectedSelected" to be selected, but "$actualSelected" is selected',
        );
      }

      stopwatch.stop();
      return StepResult.success(
        message: 'Verified exclusive selection: "$expectedSelected"',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Exclusive selection verification failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Select radio option by index in a group
  static Future<StepResult> selectByIndex(
    WidgetTester tester,
    int index, {
    String? groupName,
    RadioContext? context,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Find all radio buttons
      final radioFinders = [find.byType(Radio), find.byType(RadioListTile)];

      Finder? targetFinder;
      for (final finder in radioFinders) {
        final widgets = tester.widgetList(finder);
        if (widgets.length > index) {
          targetFinder = finder.at(index);
          break;
        }
      }

      if (targetFinder == null) {
        throw Exception('Radio button at index $index not found');
      }

      await tester.tap(targetFinder);
      await tester.pumpAndSettle();

      stopwatch.stop();
      return StepResult.success(
        message: 'Selected radio button at index $index',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Select by index failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Get all available radio options in a group
  static Future<List<String>> getAvailableOptions(
    WidgetTester tester, {
    String? groupName,
  }) async {
    final options = <String>[];

    // Look for RadioListTile widgets (they have built-in labels)
    final radioTiles = find.byType(RadioListTile);
    for (final tile in tester.widgetList(radioTiles)) {
      final radioListTile = tile as RadioListTile;
      if (radioListTile.title != null && radioListTile.title is Text) {
        final text = (radioListTile.title as Text).data;
        if (text != null) {
          options.add(text);
        }
      }
    }

    // Look for Radio widgets with nearby text labels
    final radios = find.byType(Radio);
    final texts = find.byType(Text);

    for (final radio in tester.widgetList(radios)) {
      final radioRect = tester.getRect(find.byWidget(radio));

      for (final text in tester.widgetList(texts)) {
        final textWidget = text as Text;
        final textRect = tester.getRect(find.byWidget(text));

        // Check if text is near the radio button
        final distance = (radioRect.center - textRect.center).distance;
        if (distance < 100 && textWidget.data != null) {
          options.add(textWidget.data!);
        }
      }
    }

    return options.toSet().toList(); // Remove duplicates
  }
}
