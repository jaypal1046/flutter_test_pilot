import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../step_result.dart';
import '../test_action.dart';

/// Tap a widget
class Tap extends TestAction {
  final String? widgetText;
  final String? widgetKey;
  final Type? widgetType;
  final TapContext? context;

  const Tap._({this.widgetText, this.widgetKey, this.widgetType, this.context});

  /// Tap widget by text content
  factory Tap.text(String text, {TapContext? context}) {
    return Tap._(widgetText: text, context: context);
  }

  /// Tap widget by key
  factory Tap.key(String key, {TapContext? context}) {
    return Tap._(widgetKey: key, context: context);
  }

  /// Tap widget by text with optional context for disambiguation
  factory Tap.widget(String text, {TapContext? context}) {
    return Tap._(widgetText: text, context: context);
  }

  /// Add context for disambiguation
  Tap inContext(String contextDescription) {
    return Tap._(
      widgetText: widgetText,
      widgetKey: widgetKey,
      widgetType: widgetType,
      context: TapContext._(contextDescription: contextDescription),
    );
  }

  /// Specify position for disambiguation
  Tap atPosition(String position) {
    return Tap._(
      widgetText: widgetText,
      widgetKey: widgetKey,
      widgetType: widgetType,
      context: TapContext._(position: position),
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      Finder finder;

      if (widgetKey != null) {
        finder = find.byKey(Key(widgetKey!));
      } else if (widgetText != null) {
        finder = find.text(widgetText!);

        // Handle multiple matches
        if (tester.widgetList(finder).length > 1) {
          if (context != null) {
            finder = _disambiguateFinder(finder, tester);
          } else {
            throw Exception('''
Found ${tester.widgetList(finder).length} widgets with text "$widgetText".
Use .inContext("description") or .atPosition("first|last") to disambiguate:
  
Example: Tap.widget("Submit").inContext("Policy Info")
         Tap.widget("Submit").atPosition("first")
            ''');
          }
        }
      } else if (widgetType != null) {
        finder = find.byType(widgetType!);
      } else {
        throw Exception('Must specify either text, key, or type for Tap action');
      }

      await tester.tap(finder);
      await tester.pumpAndSettle();
      stopwatch.stop();

      return StepResult.success(
        message: 'Tapped ${widgetText ?? widgetKey ?? widgetType}',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure('Tap failed: $e', duration: stopwatch.elapsed);
    }
  }

  Finder _disambiguateFinder(Finder finder, WidgetTester tester) {
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

    // For context-based disambiguation, we'd need more complex logic
    // For now, return first match
    return finder.first;
  }

  @override
  String get description => 'Tap ${widgetText ?? widgetKey ?? widgetType}';
}

class TapContext {
  final String? contextDescription;
  final String? position;

  const TapContext._({this.contextDescription, this.position});
}