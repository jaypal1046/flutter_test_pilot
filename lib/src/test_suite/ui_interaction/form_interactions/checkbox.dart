import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../step_result.dart';
import '../../test_action.dart';
import '../advanced_gestures/scroll/scroll.dart';


/// Checkbox interaction action that uses tap and scroll gestures
class CheckboxAction extends TestAction {
  final String? checkboxKey;
  final String? checkboxText;
  final String? checkboxLabel;
  final Type? checkboxType;
  final CheckboxOperation operation;
  final CheckboxContext? context;
  final Duration searchTimeout;
  final int maxScrollAttempts;
  final bool strictMode;

  const CheckboxAction._({
    this.checkboxKey,
    this.checkboxText,
    this.checkboxLabel,
    this.checkboxType,
    required this.operation,
    this.context,
    this.searchTimeout = const Duration(seconds: 10),
    this.maxScrollAttempts = 20,
    this.strictMode = false,
  });

  /// Check (select) a checkbox by key
  factory CheckboxAction.checkByKey(
    String checkboxKey, {
    CheckboxContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return CheckboxAction._(
      checkboxKey: checkboxKey,
      operation: CheckboxOperation.check,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Uncheck (deselect) a checkbox by key
  factory CheckboxAction.uncheckByKey(
    String checkboxKey, {
    CheckboxContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return CheckboxAction._(
      checkboxKey: checkboxKey,
      operation: CheckboxOperation.uncheck,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Toggle a checkbox by key
  factory CheckboxAction.toggleByKey(
    String checkboxKey, {
    CheckboxContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return CheckboxAction._(
      checkboxKey: checkboxKey,
      operation: CheckboxOperation.toggle,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Check a checkbox by label text
  factory CheckboxAction.checkByLabel(
    String labelText, {
    CheckboxContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return CheckboxAction._(
      checkboxLabel: labelText,
      operation: CheckboxOperation.check,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Uncheck a checkbox by label text
  factory CheckboxAction.uncheckByLabel(
    String labelText, {
    CheckboxContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return CheckboxAction._(
      checkboxLabel: labelText,
      operation: CheckboxOperation.uncheck,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Toggle a checkbox by label text
  factory CheckboxAction.toggleByLabel(
    String labelText, {
    CheckboxContext? context,
    Duration? searchTimeout,
    int? maxScrollAttempts,
    bool strictMode = false,
  }) {
    return CheckboxAction._(
      checkboxLabel: labelText,
      operation: CheckboxOperation.toggle,
      context: context,
      searchTimeout: searchTimeout ?? const Duration(seconds: 10),
      maxScrollAttempts: maxScrollAttempts ?? 20,
      strictMode: strictMode,
    );
  }

  /// Verify checkbox state
  factory CheckboxAction.verifyState(
    String identifier,
    bool expectedState, {
    bool byKey = false,
    CheckboxContext? context,
  }) {
    return CheckboxAction._(
      checkboxKey: byKey ? identifier : null,
      checkboxLabel: !byKey ? identifier : null,
      operation: expectedState ? CheckboxOperation.verifyChecked : CheckboxOperation.verifyUnchecked,
      context: context,
    );
  }

  /// Add context for disambiguation
  CheckboxAction inContext(String contextDescription) {
    return CheckboxAction._(
      checkboxKey: checkboxKey,
      checkboxText: checkboxText,
      checkboxLabel: checkboxLabel,
      checkboxType: checkboxType,
      operation: operation,
      context: CheckboxContext._(
        contextDescription: contextDescription,
        position: context?.position,
        groupName: context?.groupName,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      strictMode: strictMode,
    );
  }

  /// Specify position for disambiguation
  CheckboxAction atPosition(String position) {
    return CheckboxAction._(
      checkboxKey: checkboxKey,
      checkboxText: checkboxText,
      checkboxLabel: checkboxLabel,
      checkboxType: checkboxType,
      operation: operation,
      context: CheckboxContext._(
        contextDescription: context?.contextDescription,
        position: position,
        groupName: context?.groupName,
      ),
      searchTimeout: searchTimeout,
      maxScrollAttempts: maxScrollAttempts,
      strictMode: strictMode,
    );
  }

  /// Specify checkbox group
  CheckboxAction inGroup(String groupName) {
    return CheckboxAction._(
      checkboxKey: checkboxKey,
      checkboxText: checkboxText,
      checkboxLabel: checkboxLabel,
      checkboxType: checkboxType,
      operation: operation,
      context: CheckboxContext._(
        contextDescription: context?.contextDescription,
        position: context?.position,
        groupName: groupName,
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
      // Find the checkbox
      final checkboxFinder = await _findCheckbox(tester);
      
      // Perform the operation
      await _performOperation(tester, checkboxFinder);
      
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
        'Checkbox ${operation.name} failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<Finder> _findCheckbox(WidgetTester tester) async {
    final endTime = DateTime.now().add(searchTimeout);
    var scrollAttempts = 0;
    
    while (DateTime.now().isBefore(endTime) && scrollAttempts < maxScrollAttempts) {
      Finder? checkboxFinder;
      
      // Try different methods to find the checkbox
      if (checkboxKey != null) {
        checkboxFinder = find.byKey(Key(checkboxKey!));
      } else if (checkboxLabel != null) {
        checkboxFinder = _findCheckboxByLabel(tester);
      } else if (checkboxText != null) {
        checkboxFinder = find.text(checkboxText!);
      } else if (checkboxType != null) {
        checkboxFinder = find.byType(checkboxType!);
      }
      
      if (checkboxFinder != null && tester.widgetList(checkboxFinder).isNotEmpty) {
        return _disambiguateCheckbox(checkboxFinder, tester);
      }
      
      // Checkbox not found, scroll to find it
      await _scrollToFindCheckbox(tester);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      scrollAttempts++;
    }
    
    throw Exception('Checkbox not found: ${_getCheckboxIdentifier()}');
  }

  Finder _findCheckboxByLabel(WidgetTester tester) {
    // Look for checkbox with associated label
    final checkboxes = find.byType(Checkbox);
    final checkboxTiles = find.byType(CheckboxListTile);
    
    // Try CheckboxListTile first (has built-in label)
    for (final tile in tester.widgetList(checkboxTiles)) {
      final checkboxListTile = tile as CheckboxListTile;
      if (checkboxListTile.title != null) {
        final titleWidget = checkboxListTile.title!;
        if (titleWidget is Text && titleWidget.data == checkboxLabel) {
          return find.byWidget(tile);
        }
      }
    }
    
    // Look for text near checkbox widgets
    final labelFinder = find.text(checkboxLabel!);
    if (tester.widgetList(labelFinder).isNotEmpty) {
      // Find checkbox near the label
      for (final checkbox in tester.widgetList(checkboxes)) {
        final checkboxWidget = tester.getRect(find.byWidget(checkbox));
        final labelWidget = tester.getRect(labelFinder.first);
        
        // Check if checkbox and label are close to each other
        final distance = (checkboxWidget.center - labelWidget.center).distance;
        if (distance < 100) { // Adjust threshold as needed
          return find.byWidget(checkbox);
        }
      }
      
      // Fallback: tap on the label itself (might trigger checkbox)
      return labelFinder.first;
    }
    
    throw Exception('Checkbox with label "$checkboxLabel" not found');
  }

  Finder _disambiguateCheckbox(Finder finder, WidgetTester tester) {
    final widgets = tester.widgetList(finder);
    
    if (widgets.length == 1) {
      return finder.first;
    }
    
    // Multiple checkboxes found, use context to disambiguate
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
          throw Exception('Invalid position "${context!.position}" for checkbox. '
              'Use "first", "last", or a valid index.');
      }
    }
    
    if (context?.contextDescription != null) {
      // Find checkbox within specific context/ancestor
      final contextFinder = find.ancestor(
        of: finder,
        matching: find.byWidgetPredicate(
          (widget) => widget.toString().toLowerCase().contains(
            context!.contextDescription!.toLowerCase()
          ),
        ),
      );
      if (tester.widgetList(contextFinder).isNotEmpty) {
        return contextFinder.first;
      }
    }
    
    if (context?.groupName != null) {
      // Look for checkboxes in a specific group/form section
      final groupFinder = find.text(context!.groupName!);
      if (tester.widgetList(groupFinder).isNotEmpty) {
        final groupRect = tester.getRect(groupFinder.first);
        
        // Find checkboxes near the group title
        for (int i = 0; i < widgets.length; i++) {
          final checkboxRect = tester.getRect(finder.at(i));
          if ((checkboxRect.center - groupRect.center).distance < 200) {
            return finder.at(i);
          }
        }
      }
    }
    
    throw Exception('''
Found ${widgets.length} checkboxes matching criteria.
Use .inContext("description"), .atPosition("first|last|index"), or .inGroup("group name") to disambiguate:

Example: CheckboxAction.checkByLabel("Accept Terms").inContext("Registration Form")
         CheckboxAction.checkByKey("privacy_checkbox").atPosition("first")
         CheckboxAction.toggleByLabel("Newsletter").inGroup("Preferences")
''');
  }

  Future<void> _performOperation(WidgetTester tester, Finder checkboxFinder) async {
    final currentState = _getCheckboxState(tester, checkboxFinder);
    
    switch (operation) {
      case CheckboxOperation.check:
        if (!currentState) {
          await _tapCheckbox(tester, checkboxFinder);
        } else if (strictMode) {
          throw Exception('Checkbox is already checked');
        }
        break;
        
      case CheckboxOperation.uncheck:
        if (currentState) {
          await _tapCheckbox(tester, checkboxFinder);
        } else if (strictMode) {
          throw Exception('Checkbox is already unchecked');
        }
        break;
        
      case CheckboxOperation.toggle:
        await _tapCheckbox(tester, checkboxFinder);
        break;
        
      case CheckboxOperation.verifyChecked:
        if (!currentState) {
          throw Exception('Expected checkbox to be checked, but it was unchecked');
        }
        break;
        
      case CheckboxOperation.verifyUnchecked:
        if (currentState) {
          throw Exception('Expected checkbox to be unchecked, but it was checked');
        }
        break;
    }
  }

  Future<void> _tapCheckbox(WidgetTester tester, Finder checkboxFinder) async {
    await tester.tap(checkboxFinder);
    await tester.pump(const Duration(milliseconds: 100));
  }

  bool _getCheckboxState(WidgetTester tester, Finder checkboxFinder) {
    final widget = tester.widget(checkboxFinder);
    
    if (widget is Checkbox) {
      return widget.value ?? false;
    } else if (widget is CheckboxListTile) {
      return widget.value ?? false;
    } else {
      // For custom checkbox widgets, try to determine state by looking for checkmarks
      final checkmarkFinder = find.descendant(
        of: checkboxFinder,
        matching: find.byIcon(Icons.check),
      );
      return tester.widgetList(checkmarkFinder).isNotEmpty;
    }
  }

  Future<void> _scrollToFindCheckbox(WidgetTester tester) async {
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

  String _getCheckboxIdentifier() {
    return checkboxKey ?? checkboxLabel ?? checkboxText ?? checkboxType?.toString() ?? 'unknown';
  }

  String _getSuccessMessage() {
    final identifier = _getCheckboxIdentifier();
    switch (operation) {
      case CheckboxOperation.check:
        return 'Checked checkbox: $identifier';
      case CheckboxOperation.uncheck:
        return 'Unchecked checkbox: $identifier';
      case CheckboxOperation.toggle:
        return 'Toggled checkbox: $identifier';
      case CheckboxOperation.verifyChecked:
        return 'Verified checkbox is checked: $identifier';
      case CheckboxOperation.verifyUnchecked:
        return 'Verified checkbox is unchecked: $identifier';
    }
  }

  @override
  String get description => '${operation.name} checkbox: ${_getCheckboxIdentifier()}';
}

enum CheckboxOperation {
  check,
  uncheck,
  toggle,
  verifyChecked,
  verifyUnchecked,
}

class CheckboxContext {
  final String? contextDescription;
  final String? position;
  final String? groupName;

  const CheckboxContext._({
    this.contextDescription,
    this.position,
    this.groupName,
  });
}

/// Convenience classes for common checkbox operations
class CheckBox {
  /// Check a checkbox
  static CheckboxAction check(String identifier, {bool byKey = false, CheckboxContext? context}) {
    return byKey 
        ? CheckboxAction.checkByKey(identifier, context: context)
        : CheckboxAction.checkByLabel(identifier, context: context);
  }

  /// Uncheck a checkbox  
  static CheckboxAction uncheck(String identifier, {bool byKey = false, CheckboxContext? context}) {
    return byKey 
        ? CheckboxAction.uncheckByKey(identifier, context: context)
        : CheckboxAction.uncheckByLabel(identifier, context: context);
  }

  /// Toggle a checkbox
  static CheckboxAction toggle(String identifier, {bool byKey = false, CheckboxContext? context}) {
    return byKey 
        ? CheckboxAction.toggleByKey(identifier, context: context)
        : CheckboxAction.toggleByLabel(identifier, context: context);
  }

  /// Verify checkbox state
  static CheckboxAction verify(String identifier, bool shouldBeChecked, {bool byKey = false}) {
    return CheckboxAction.verifyState(identifier, shouldBeChecked, byKey: byKey);
  }
}

/// Extended checkbox actions for complex scenarios
class CheckboxActions {
  
  /// Select multiple checkboxes in a group
  static Future<StepResult> selectMultiple(
    WidgetTester tester,
    List<String> checkboxLabels, {
    CheckboxContext? context,
    bool byKey = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final results = <String>[];
    
    try {
      for (final label in checkboxLabels) {
        final action = byKey 
            ? CheckboxAction.checkByKey(label, context: context)
            : CheckboxAction.checkByLabel(label, context: context);
            
        final result = await action.execute(tester);
        if (result.success) {
          results.add(label);
        } else {
          throw Exception('Failed to check $label: ${result.message}');
        }
        
        await tester.pump(const Duration(milliseconds: 200));
      }
      
      stopwatch.stop();
      return StepResult.success(
        message: 'Checked ${results.length} checkboxes: ${results.join(", ")}',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Multi-checkbox selection failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Uncheck all checkboxes in a group
  static Future<StepResult> uncheckAll(
    WidgetTester tester,
    List<String> checkboxLabels, {
    CheckboxContext? context,
    bool byKey = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final results = <String>[];
    
    try {
      for (final label in checkboxLabels) {
        final action = byKey 
            ? CheckboxAction.uncheckByKey(label, context: context)
            : CheckboxAction.uncheckByLabel(label, context: context);
            
        final result = await action.execute(tester);
        if (result.success) {
          results.add(label);
        }
        
        await tester.pump(const Duration(milliseconds: 200));
      }
      
      stopwatch.stop();
      return StepResult.success(
        message: 'Unchecked ${results.length} checkboxes: ${results.join(", ")}',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Multi-checkbox uncheck failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Check all checkboxes of a specific type
  static Future<StepResult> checkAllOfType(
    WidgetTester tester,
    Type checkboxType,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final finder = find.byType(checkboxType);
      final checkboxes = tester.widgetList(finder);
      var checkedCount = 0;
      
      for (int i = 0; i < checkboxes.length; i++) {
        final checkboxFinder = finder.at(i);
        final widget = tester.widget(checkboxFinder);
        
        bool isChecked = false;
        if (widget is Checkbox) {
          isChecked = widget.value ?? false;
        } else if (widget is CheckboxListTile) {
          isChecked = widget.value ?? false;
        }
        
        if (!isChecked) {
          await tester.tap(checkboxFinder);
          await tester.pump(const Duration(milliseconds: 100));
          checkedCount++;
        }
      }
      
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      return StepResult.success(
        message: 'Checked $checkedCount out of ${checkboxes.length} checkboxes',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Check all of type failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Get states of all checkboxes in a group
  static Future<Map<String, bool>> getGroupStates(
    WidgetTester tester,
    List<String> checkboxLabels, {
    bool byKey = false,
  }) async {
    final states = <String, bool>{};
    
    for (final label in checkboxLabels) {
      try {
        final action = CheckboxAction.verifyState(label, true, byKey: byKey);
        final checkboxFinder = await action._findCheckbox(tester);
        final state = action._getCheckboxState(tester, checkboxFinder);
        states[label] = state;
      } catch (e) {
        states[label] = false; // Default to unchecked if not found
      }
    }
    
    return states;
  }
}