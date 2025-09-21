import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import '../../step_result.dart';
import '../../test_action.dart';

/// Universal switch component for testing - can toggle any type of switch
class SwitchAction extends TestAction {
  final SwitchState? targetState;
  final String? targetKey;
  final String? targetText;
  final Type? targetType;
  final SwitchContext? context;
  final SwitchActionType actionType;

  const SwitchAction._({
    this.targetState,
    this.targetKey,
    this.targetText,
    this.targetType,
    this.context,
    this.actionType = SwitchActionType.toggle,
  });

  /// Toggle switch (turn on if off, turn off if on)
  factory SwitchAction.toggle({
    String? key,
    String? text,
    Type? type,
    SwitchContext? context,
  }) {
    return SwitchAction._(
      targetKey: key,
      targetText: text,
      targetType: type,
      context: context,
      actionType: SwitchActionType.toggle,
    );
  }

  /// Turn switch ON
  factory SwitchAction.turnOn({
    String? key,
    String? text,
    Type? type,
    SwitchContext? context,
  }) {
    return SwitchAction._(
      targetState: SwitchState.on,
      targetKey: key,
      targetText: text,
      targetType: type,
      context: context,
      actionType: SwitchActionType.setState,
    );
  }

  /// Turn switch OFF
  factory SwitchAction.turnOff({
    String? key,
    String? text,
    Type? type,
    SwitchContext? context,
  }) {
    return SwitchAction._(
      targetState: SwitchState.off,
      targetKey: key,
      targetText: text,
      targetType: type,
      context: context,
      actionType: SwitchActionType.setState,
    );
  }

  /// Find switch by text label and toggle
  factory SwitchAction.byText(String text, {SwitchState? state}) {
    return SwitchAction._(
      targetText: text,
      targetState: state,
      actionType: state != null
          ? SwitchActionType.setState
          : SwitchActionType.toggle,
    );
  }

  /// Find switch by key and toggle
  factory SwitchAction.byKey(String key, {SwitchState? state}) {
    return SwitchAction._(
      targetKey: key,
      targetState: state,
      actionType: state != null
          ? SwitchActionType.setState
          : SwitchActionType.toggle,
    );
  }

  /// Add context for widget disambiguation
  SwitchAction inContainer(String containerDescription) {
    return SwitchAction._(
      targetState: targetState,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      actionType: actionType,
      context: SwitchContext._(containerDescription: containerDescription),
    );
  }

  /// Specify position for disambiguation
  SwitchAction atPosition(String position) {
    return SwitchAction._(
      targetState: targetState,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      actionType: actionType,
      context: SwitchContext._(position: position),
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      Finder switchFinder = _findSwitchWidget(tester);
      bool currentState = _getCurrentSwitchState(tester, switchFinder);
      bool shouldToggle = _shouldToggleSwitch(currentState);

      if (shouldToggle) {
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();
      }

      stopwatch.stop();

      return StepResult.success(
        message: _getSuccessMessage(currentState, shouldToggle),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Switch action failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Finder _findSwitchWidget(WidgetTester tester) {
    Finder finder;

    if (targetKey != null) {
      finder = find.byKey(Key(targetKey!));
    } else if (targetText != null) {
      // Try to find switch by semantics label first
      finder = find.bySemanticsLabel(targetText!);

      // Filter to only switch widgets
      if (tester.widgetList(finder).isNotEmpty) {
        finder = _filterToSwitchTypes(finder, tester);
      }

      if (tester.widgetList(finder).isEmpty) {
        // Fallback: find switch near the text
        finder = _findSwitchNearText(tester, targetText!);
      }
    } else if (targetType != null) {
      finder = find.byType(targetType!);
    } else {
      // Find any switch widget
      finder = _findAnySwitchWidget(tester);
    }

    if (tester.widgetList(finder).isEmpty) {
      throw Exception('No switch widget found with specified criteria');
    }

    // Handle multiple matches
    if (tester.widgetList(finder).length > 1) {
      finder = _disambiguateSwitchFinder(finder, tester);
    }

    return finder;
  }

  Finder _filterToSwitchTypes(Finder baseFinder, WidgetTester tester) {
    final switchTypes = [Switch, CupertinoSwitch, SwitchListTile];

    for (final switchType in switchTypes) {
      final filtered = find.descendant(
        of: baseFinder,
        matching: find.byType(switchType),
      );
      if (tester.widgetList(filtered).isNotEmpty) {
        return filtered;
      }
    }

    return baseFinder;
  }

  Finder _findSwitchNearText(WidgetTester tester, String text) {
    final textFinder = find.text(text);
    if (tester.widgetList(textFinder).isEmpty) {
      return find.byType(Switch); // Fallback
    }

    // Look for switch as ancestor of the text
    Finder switchFinder = find.ancestor(
      of: textFinder,
      matching: _getSwitchTypeFinder(),
    );

    if (tester.widgetList(switchFinder).isNotEmpty) {
      return switchFinder;
    }

    // Look for switch as sibling (in same parent container)
    final parentFinder = find.ancestor(
      of: textFinder,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container ||
            widget is Row ||
            widget is Column ||
            widget is ListTile ||
            widget is Card,
      ),
    );

    if (tester.widgetList(parentFinder).isNotEmpty) {
      switchFinder = find.descendant(
        of: parentFinder.first,
        matching: _getSwitchTypeFinder(),
      );

      if (tester.widgetList(switchFinder).isNotEmpty) {
        return switchFinder;
      }
    }

    // Last resort: find any switch
    return _findAnySwitchWidget(tester);
  }

  Finder _getSwitchTypeFinder() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Switch ||
          widget is CupertinoSwitch ||
          widget is SwitchListTile,
    );
  }

  Finder _findAnySwitchWidget(WidgetTester tester) {
    final switchFinders = [
      find.byType(Switch),
      find.byType(CupertinoSwitch),
      find.byType(SwitchListTile),
    ];

    for (final finder in switchFinders) {
      if (tester.widgetList(finder).isNotEmpty) {
        return finder;
      }
    }

    throw Exception('No switch widgets found in the widget tree');
  }

  Finder _disambiguateSwitchFinder(Finder finder, WidgetTester tester) {
    if (context?.position != null) {
      switch (context!.position!.toLowerCase()) {
        case 'first':
          return finder.first;
        case 'last':
          return finder.last;
        default:
          final index = int.tryParse(context!.position!);
          if (index != null && index < tester.widgetList(finder).length) {
            return finder.at(index);
          }
          throw Exception(
            'Invalid position "${context!.position}" for switch. '
            'Use "first", "last", or a valid index.',
          );
      }
    }

    if (context?.containerDescription != null) {
      // Try to find switch within specific container
      // For now, return first match - in real implementation, search by context
      return finder.first;
    }

    throw Exception('''
Found ${tester.widgetList(finder).length} switch widgets.
Use .inContainer("description") or .atPosition("first|last|index") to disambiguate:

Example: SwitchAction.byText("Dark Mode").inContainer("Settings")
         SwitchAction.toggle().atPosition("first")
''');
  }

  bool _getCurrentSwitchState(WidgetTester tester, Finder finder) {
    try {
      // Try to get the state from semantics first (most reliable)
      final element = tester.element(finder);
      final semantics = element.renderObject?.debugSemantics;

      if (semantics != null) {
        // Check if switch is checked/unchecked in semantics using flagsCollection
        // Convert CheckedState to bool
        final checkedState = semantics.flagsCollection.isChecked;
        switch (checkedState) {
          case ui.CheckedState.isTrue:
            return true;
          case ui.CheckedState.isFalse:
            return false;
          case ui.CheckedState.mixed:
            // Handle mixed state - you might want to treat this differently
            return false; // or true, depending on your needs
          case ui.CheckedState.none:
            return false;
        }
      }

      // Fallback: Try to get widget and cast to specific types
      final widget = tester.widget(finder);

      // We need to cast to the actual widget type to access value property
      if (widget.runtimeType.toString() == 'Switch') {
        final switchWidget = widget as dynamic;
        return switchWidget.value as bool;
      } else if (widget.runtimeType.toString() == 'CupertinoSwitch') {
        final cupertinoSwitch = widget as dynamic;
        return cupertinoSwitch.value as bool;
      } else if (widget.runtimeType.toString() == 'SwitchListTile') {
        final switchListTile = widget as dynamic;
        return (switchListTile.value as bool?) ?? false;
      }
    } catch (e) {
      // If all else fails, assume false and let the toggle happen
      print('Could not determine switch state: $e');
    }

    return false; // Default to false (off)
  }

  bool _shouldToggleSwitch(bool currentState) {
    if (actionType == SwitchActionType.toggle) {
      return true; // Always toggle
    } else if (actionType == SwitchActionType.setState) {
      if (targetState == SwitchState.on) {
        return !currentState; // Only toggle if currently off
      } else if (targetState == SwitchState.off) {
        return currentState; // Only toggle if currently on
      }
    }

    return false;
  }

  String _getSuccessMessage(bool currentState, bool didToggle) {
    String target =
        targetText ?? targetKey ?? targetType?.toString() ?? 'switch';

    if (!didToggle) {
      String stateStr = targetState == SwitchState.on ? 'ON' : 'OFF';
      return 'Switch "$target" was already $stateStr';
    }

    if (actionType == SwitchActionType.toggle) {
      String newState = currentState ? 'OFF' : 'ON';
      return 'Toggled switch "$target" to $newState';
    } else {
      String newState = targetState == SwitchState.on ? 'ON' : 'OFF';
      return 'Set switch "$target" to $newState';
    }
  }

  @override
  String get description {
    String target =
        targetText ?? targetKey ?? targetType?.toString() ?? 'switch';

    if (actionType == SwitchActionType.toggle) {
      return 'Toggle switch "$target"';
    } else {
      String stateStr = targetState == SwitchState.on ? 'ON' : 'OFF';
      return 'Set switch "$target" to $stateStr';
    }
  }
}

enum SwitchState { on, off }

enum SwitchActionType { toggle, setState }

class SwitchContext {
  final String? containerDescription;
  final String? position;

  const SwitchContext._({this.containerDescription, this.position});
}

/// Convenience classes for different switch types
class Switch extends SwitchAction {
  Switch.toggle({String? key, String? text, Type? type, super.context})
    : super._(
        targetKey: key,
        targetText: text,
        targetType: type,
        actionType: SwitchActionType.toggle,
      );

  Switch.on({String? key, String? text, Type? type, super.context})
    : super._(
        targetKey: key,
        targetText: text,
        targetType: type,
        targetState: SwitchState.on,
        actionType: SwitchActionType.setState,
      );

  Switch.off({String? key, String? text, Type? type, super.context})
    : super._(
        targetKey: key,
        targetText: text,
        targetType: type,
        targetState: SwitchState.off,
        actionType: SwitchActionType.setState,
      );
}

/// Extension methods for common switch scenarios
extension SwitchExtensions on SwitchAction {
  /// Enable a feature switch
  static SwitchAction enable(String featureName) =>
      SwitchAction.turnOn(text: featureName);

  /// Disable a feature switch
  static SwitchAction disable(String featureName) =>
      SwitchAction.turnOff(text: featureName);

  /// Toggle notification settings
  static SwitchAction notification(String type, {SwitchState? state}) =>
      SwitchAction.byText("$type notifications", state: state);

  /// Toggle dark mode
  static SwitchAction darkMode({SwitchState? state}) =>
      SwitchAction.byText("Dark mode", state: state);

  /// Toggle WiFi/Bluetooth/etc
  static SwitchAction connectivity(String type, {SwitchState? state}) =>
      SwitchAction.byText(type, state: state);
}
