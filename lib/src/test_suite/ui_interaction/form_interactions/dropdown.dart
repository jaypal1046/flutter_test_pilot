import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../step_result.dart';
import '../../test_action.dart';
import '../advanced_gestures/scroll/scroll.dart';
import '../tap/tap.dart';

/// Dropdown value selection action that combines tap and scroll gestures
class DropdownSelect extends TestAction {
  final String? dropdownKey;
  final String? dropdownText;
  final Type? dropdownType;
  final String valueToSelect;
  final DropdownContext? context;
  final Duration searchTimeout;
  final int maxScrollAttempts;
  final bool caseSensitive;

  const DropdownSelect._({
    this.dropdownKey,
    this.dropdownText,
    this.dropdownType,
    required this.valueToSelect,
    this.context,
    this.searchTimeout = const Duration(seconds: 10),
    this.maxScrollAttempts = 20,
    this.caseSensitive = false,
  });

  /// Select dropdown value by dropdown key
  factory DropdownSelect.byKey(
    String dropdownKey,
    String value, {
    DropdownContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool caseSensitive = false,
  }) {
    return DropdownSelect._(
      dropdownKey: dropdownKey,
      valueToSelect: value,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      caseSensitive: caseSensitive,
    );
  }

  /// Select dropdown value by dropdown text
  factory DropdownSelect.byText(
    String dropdownText,
    String value, {
    DropdownContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool caseSensitive = false,
  }) {
    return DropdownSelect._(
      dropdownText: dropdownText,
      valueToSelect: value,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      caseSensitive: caseSensitive,
    );
  }

  /// Select dropdown value by dropdown type
  factory DropdownSelect.byType(
    Type dropdownType,
    String value, {
    DropdownContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool caseSensitive = false,
  }) {
    return DropdownSelect._(
      dropdownType: dropdownType,
      valueToSelect: value,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      caseSensitive: caseSensitive,
    );
  }

  /// Add context for disambiguation
  DropdownSelect inContext(String contextDescription) {
    return DropdownSelect._(
      dropdownKey: dropdownKey,
      dropdownText: dropdownText,
      dropdownType: dropdownType,
      valueToSelect: valueToSelect,
      context: DropdownContext._(
        contextDescription: contextDescription,
        position: context?.position,
        dropdownType: context?.dropdownType,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      caseSensitive: caseSensitive,
    );
  }

  /// Specify position for disambiguation
  DropdownSelect atPosition(String position) {
    return DropdownSelect._(
      dropdownKey: dropdownKey,
      dropdownText: dropdownText,
      dropdownType: dropdownType,
      valueToSelect: valueToSelect,
      context: DropdownContext._(
        contextDescription: context?.contextDescription,
        position: position,
        dropdownType: context?.dropdownType,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      caseSensitive: caseSensitive,
    );
  }

  /// Specify dropdown type for better handling
  DropdownSelect ofType(DropdownType type) {
    return DropdownSelect._(
      dropdownKey: dropdownKey,
      dropdownText: dropdownText,
      dropdownType: dropdownType,
      valueToSelect: valueToSelect,
      context: DropdownContext._(
        contextDescription: context?.contextDescription,
        position: context?.position,
        dropdownType: type,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      caseSensitive: caseSensitive,
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Find and open the dropdown
      await _openDropdown(tester);

      // Step 2: Wait for dropdown to be fully opened
      await tester.pumpAndSettle();

      // Step 3: Find and select the value
      await _selectValue(tester);

      // Step 4: Wait for selection to complete
      await tester.pumpAndSettle();

      stopwatch.stop();

      return StepResult.success(
        message: 'Selected "$valueToSelect" from dropdown',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Dropdown selection failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<void> _openDropdown(WidgetTester tester) async {
    // Find the dropdown trigger
    final dropdownFinder = _findDropdownTrigger(tester);

    // Determine the best way to open the dropdown
    final dropdownType =
        context?.dropdownType ?? _detectDropdownType(tester, dropdownFinder);

    switch (dropdownType) {
      case DropdownType.material:
      case DropdownType.cupertino:
      case DropdownType.custom:
        // Standard tap to open
        final tapAction = Tap.widget(
          dropdownKey ?? dropdownText ?? dropdownType.toString(),
        );
        await tapAction.execute(tester);
        break;

      case DropdownType.searchable:
        // Might need to tap on search field first
        final tapAction = Tap.widget(
          dropdownKey ?? dropdownText ?? dropdownType.toString(),
        );
        await tapAction.execute(tester);
        break;

      case DropdownType.multiSelect:
        // Open multi-select dropdown
        final tapAction = Tap.widget(
          dropdownKey ?? dropdownText ?? dropdownType.toString(),
        );
        await tapAction.execute(tester);
        break;
    }
  }

  Future<void> _selectValue(WidgetTester tester) async {
    final endTime = DateTime.now().add(searchTimeout);
    var scrollAttempts = 0;

    while (DateTime.now().isBefore(endTime) &&
        scrollAttempts < maxScrollAttempts) {
      // Try to find the value in current view
      final valueFinder = _findValueInDropdown(tester);

      if (tester.widgetList(valueFinder).isNotEmpty) {
        // Found the value, tap it
        final tapAction = TapAction.text(valueToSelect);
        await tapAction.execute(tester);
        return;
      }

      // Value not visible, scroll to find it
      await _scrollInDropdown(tester);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      scrollAttempts++;
    }

    throw Exception(
      'Value "$valueToSelect" not found in dropdown after $scrollAttempts scroll attempts',
    );
  }

  Finder _findDropdownTrigger(WidgetTester tester) {
    if (dropdownKey != null) {
      return find.byKey(Key(dropdownKey!));
    } else if (dropdownText != null) {
      return find.text(dropdownText!);
    } else if (dropdownType != null) {
      return find.byType(dropdownType!);
    } else {
      throw Exception('Must specify dropdown key, text, or type');
    }
  }

  Finder _findValueInDropdown(WidgetTester tester) {
    if (caseSensitive) {
      return find.text(valueToSelect);
    } else {
      // Case-insensitive search
      return find.byWidgetPredicate((widget) {
        if (widget is Text) {
          final text = widget.data?.toLowerCase() ?? '';
          return text == valueToSelect.toLowerCase();
        } else if (widget is RichText) {
          final text = widget.text.toPlainText().toLowerCase();
          return text == valueToSelect.toLowerCase();
        }
        return false;
      });
    }
  }

  Future<void> _scrollInDropdown(WidgetTester tester) async {
    try {
      // Find scrollable container in dropdown
      final scrollableTypes = [
        find.byType(ListView),
        find.byType(GridView),
        find.byType(SingleChildScrollView),
        find.byType(Scrollable),
      ];

      Finder? scrollableFinder;
      for (final finder in scrollableTypes) {
        if (tester.widgetList(finder).isNotEmpty) {
          scrollableFinder =
              finder.last; // Use last to get the dropdown's scrollable
          break;
        }
      }

      if (scrollableFinder != null) {
        // Scroll down in the dropdown
        await tester.drag(scrollableFinder, const Offset(0, -100));
      } else {
        // Fallback: try scrolling the entire screen
        final scroll = Scroll.down(distance: 100);
        await scroll.execute(tester);
      }
    } catch (e) {
      // If scrolling fails, continue anyway - the value might be findable without scrolling
    }
  }

  DropdownType _detectDropdownType(WidgetTester tester, Finder dropdownFinder) {
    final widget = tester.widget(dropdownFinder);

    if (widget is DropdownButton) {
      return DropdownType.material;
    } else if (widget.runtimeType.toString().toLowerCase().contains(
      'cupertino',
    )) {
      return DropdownType.cupertino;
    } else if (widget.runtimeType.toString().toLowerCase().contains('search')) {
      return DropdownType.searchable;
    } else if (widget.runtimeType.toString().toLowerCase().contains('multi')) {
      return DropdownType.multiSelect;
    }

    return DropdownType.custom;
  }

  @override
  String get description =>
      'Select "$valueToSelect" from dropdown (${dropdownKey ?? dropdownText ?? dropdownType})';
}

enum DropdownType { material, cupertino, searchable, multiSelect, custom }

class DropdownContext {
  final String? contextDescription;
  final String? position;
  final DropdownType? dropdownType;

  const DropdownContext._({
    this.contextDescription,
    this.position,
    this.dropdownType,
  });
}

/// Extended dropdown actions for specific scenarios
class DropdownActions {
  /// Select multiple values from a multi-select dropdown
  static Future<StepResult> selectMultiple(
    WidgetTester tester,
    String dropdownIdentifier,
    List<String> values, {
    DropdownContext? context,
    bool byKey = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      for (final value in values) {
        final selectAction = byKey
            ? DropdownSelect.byKey(dropdownIdentifier, value, context: context)
            : DropdownSelect.byText(
                dropdownIdentifier,
                value,
                context: context,
              );

        await selectAction.execute(tester);
        await tester.pump(const Duration(milliseconds: 200));
      }

      stopwatch.stop();
      return StepResult.success(
        message: 'Selected ${values.length} values: ${values.join(", ")}',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Multi-select failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Clear all selections from a multi-select dropdown
  static Future<StepResult> clearAll(
    WidgetTester tester,
    String dropdownIdentifier, {
    DropdownContext? context,
    bool byKey = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Look for clear/reset button
      final clearFinders = [
        find.text('Clear All'),
        find.text('Reset'),
        find.text('Clear'),
        find.byIcon(Icons.clear),
        find.byIcon(Icons.close),
      ];

      for (final finder in clearFinders) {
        if (tester.widgetList(finder).isNotEmpty) {
          final tapAction = TapAction.text(finder.toString());
          await tapAction.execute(tester);
          stopwatch.stop();
          return StepResult.success(
            message: 'Cleared all selections',
            duration: stopwatch.elapsed,
          );
        }
      }

      throw Exception('No clear button found');
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Clear all failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Search and select in a searchable dropdown
  static Future<StepResult> searchAndSelect(
    WidgetTester tester,
    String dropdownIdentifier,
    String searchTerm,
    String valueToSelect, {
    DropdownContext? context,
    bool byKey = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // First open the dropdown
      final openAction = byKey
          ? Tap.key(dropdownIdentifier)
          : Tap.text(dropdownIdentifier);
      await openAction.execute(tester);

      // Find search field and enter search term
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, searchTerm);
      await tester.pumpAndSettle();

      // Select the value
      final selectAction = TapAction.text(valueToSelect);
      await selectAction.execute(tester);

      stopwatch.stop();
      return StepResult.success(
        message: 'Searched "$searchTerm" and selected "$valueToSelect"',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Search and select failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }
}
