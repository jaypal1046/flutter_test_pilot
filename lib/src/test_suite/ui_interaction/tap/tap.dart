import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../step_result.dart';
import '../../test_action.dart';

/// Enum to represent different tap gesture types
enum GestureType { singleTap, doubleTap, tripleTap, longPress }

/// Base class for tap-related actions
abstract class TapAction extends TestAction {
  final String? widgetText;
  final String? widgetKey;
  final Type? widgetType;
  final Finder? customFinder;  // NEW: Support for custom Finder
  final TapContext? context;
  final GestureType gestureType;

  const TapAction._({
    this.widgetText,
    this.widgetKey,
    this.widgetType,
    this.customFinder,  // NEW
    this.context,
    required this.gestureType,
  });

  /// Tap widget by text content
  factory TapAction.text(
    String text, {
    TapContext? context,
    GestureType gestureType = GestureType.singleTap,
  }) {
    return _TapActionImpl(
      widgetText: text,
      context: context,
      gestureType: gestureType,
    );
  }

  /// Tap widget by key
  factory TapAction.key(
    String key, {
    TapContext? context,
    GestureType gestureType = GestureType.singleTap,
  }) {
    return _TapActionImpl(
      widgetKey: key,
      context: context,
      gestureType: gestureType,
    );
  }

  /// Tap widget by text OR by custom Finder
  /// 
  /// Examples:
  /// ```dart
  /// // Tap by text
  /// TapAction.widget('Submit')
  /// 
  /// // Tap by Finder (BackButton)
  /// TapAction.widget(find.byType(BackButton))
  /// 
  /// // Tap by icon
  /// TapAction.widget(find.byIcon(Icons.arrow_back))
  /// 
  /// // Tap by widget predicate
  /// TapAction.widget(find.byWidgetPredicate((w) => w is IconButton))
  /// ```
  factory TapAction.widget(
    dynamic textOrFinder, {
    TapContext? context,
    GestureType gestureType = GestureType.singleTap,
  }) {
    if (textOrFinder is String) {
      return _TapActionImpl(
        widgetText: textOrFinder,
        context: context,
        gestureType: gestureType,
      );
    } else if (textOrFinder is Finder) {
      return _TapActionImpl(
        customFinder: textOrFinder,
        context: context,
        gestureType: gestureType,
      );
    } else {
      throw ArgumentError(
        'TapAction.widget() expects either String or Finder, got ${textOrFinder.runtimeType}',
      );
    }
  }

  /// Tap widget by Type
  /// 
  /// Example:
  /// ```dart
  /// TapAction.byType(BackButton)
  /// TapAction.byType(IconButton)
  /// ```
  factory TapAction.byType(
    Type widgetType, {
    TapContext? context,
    GestureType gestureType = GestureType.singleTap,
  }) {
    return _TapActionImpl(
      widgetType: widgetType,
      context: context,
      gestureType: gestureType,
    );
  }

  /// Tap widget by icon
  /// 
  /// Example:
  /// ```dart
  /// TapAction.icon(Icons.arrow_back)
  /// TapAction.icon(Icons.close)
  /// ```
  factory TapAction.icon(
    IconData icon, {
    TapContext? context,
    GestureType gestureType = GestureType.singleTap,
  }) {
    return _TapActionImpl(
      customFinder: find.byIcon(icon),
      context: context,
      gestureType: gestureType,
    );
  }

  /// Add context for disambiguation
  TapAction inContext(String contextDescription) {
    return _TapActionImpl(
      widgetText: widgetText,
      widgetKey: widgetKey,
      widgetType: widgetType,
      customFinder: customFinder,
      context: TapContext._(contextDescription: contextDescription),
      gestureType: gestureType,
    );
  }

  /// Specify position for disambiguation
  TapAction atPosition(String position) {
    return _TapActionImpl(
      widgetText: widgetText,
      widgetKey: widgetKey,
      widgetType: widgetType,
      customFinder: customFinder,
      context: TapContext._(position: position),
      gestureType: gestureType,
    );
  }

  /// Perform the specific gesture on the found widget
  Future<void> performGesture(Finder finder, WidgetTester tester) async {
    switch (gestureType) {
      case GestureType.singleTap:
        await tester.tap(finder);
        break;
      case GestureType.doubleTap:
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(finder);
        break;
      case GestureType.tripleTap:
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(finder);
        break;
      case GestureType.longPress:
        await tester.longPress(finder);
        break;
    }
    await tester.pumpAndSettle();
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      Finder finder = _findWidget(tester);

      await performGesture(finder, tester);
      stopwatch.stop();

      return StepResult.success(
        message:
            '${gestureType.name} on ${widgetText ?? widgetKey ?? widgetType ?? 'custom widget'}',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        '${gestureType.name} failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Finder _findWidget(WidgetTester tester) {
    Finder finder;

    // NEW: Prioritize custom finder if provided
    if (customFinder != null) {
      finder = customFinder!;
    } else if (widgetKey != null) {
      finder = find.byKey(Key(widgetKey!));
    } else if (widgetText != null) {
      finder = find.text(widgetText!);
      if (tester.widgetList(finder).length > 1) {
        finder = _disambiguateFinder(finder, tester);
      }
    } else if (widgetType != null) {
      finder = find.byType(widgetType!);
    } else {
      throw Exception(
        'Must specify either text, key, type, or finder for ${gestureType.name} action',
      );
    }

    if (tester.widgetList(finder).isEmpty) {
      throw Exception(
        'No widget found for ${gestureType.name} with ${widgetText ?? widgetKey ?? widgetType ?? 'custom finder'}',
      );
    }

    // Handle disambiguation for custom finders
    if (customFinder != null && tester.widgetList(finder).length > 1) {
      finder = _disambiguateFinder(finder, tester);
    }

    return finder;
  }

  Finder _disambiguateFinder(Finder finder, WidgetTester tester) {
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
            'Invalid position "${context!.position}" for ${gestureType.name}. '
            'Use "first", "last", or a valid index.',
          );
      }
    }

    if (context?.contextDescription != null) {
      // Attempt to find widget within a specific ancestor or context
      final contextFinder = find.ancestor(
        of: finder,
        matching: find.byWidgetPredicate(
          (widget) => widget.toString().toLowerCase().contains(
            context!.contextDescription!.toLowerCase(),
          ),
        ),
      );
      if (tester.widgetList(contextFinder).isNotEmpty) {
        return contextFinder;
      }
    }

    throw Exception('''
Found ${tester.widgetList(finder).length} widgets with text "$widgetText" for ${gestureType.name}.
Use .inContext("description") or .atPosition("first|last|index") to disambiguate:

Example: TapAction.widget("Submit").inContext("Policy Info")
         TapAction.widget("Submit").atPosition("first")
''');
  }

  @override
  String get description =>
      '${gestureType.name} ${widgetText ?? widgetKey ?? widgetType ?? 'widget'}';
}

class _TapActionImpl extends TapAction {
  const _TapActionImpl({
    super.widgetText,
    super.widgetKey,
    super.widgetType,
    super.customFinder,  // NEW
    super.context,
    required super.gestureType,
  }) : super._();
}

class TapContext {
  final String? contextDescription;
  final String? position;

  const TapContext._({this.contextDescription, this.position});
}

/// Convenience methods for specific tap actions
class Tap extends TapAction {
  Tap.text(String text, {super.context})
    : super._(widgetText: text, gestureType: GestureType.singleTap);

  Tap.key(String key, {super.context})
    : super._(widgetKey: key, gestureType: GestureType.singleTap);

  Tap.widget(String text, {super.context})
    : super._(widgetText: text, gestureType: GestureType.singleTap);
}

class DoubleTap extends TapAction {
  DoubleTap.text(String text, {super.context})
    : super._(widgetText: text, gestureType: GestureType.doubleTap);

  DoubleTap.key(String key, {super.context})
    : super._(widgetKey: key, gestureType: GestureType.doubleTap);

  DoubleTap.widget(String text, {super.context})
    : super._(widgetText: text, gestureType: GestureType.doubleTap);
}

class TripleTap extends TapAction {
  TripleTap.text(String text, {super.context})
    : super._(widgetText: text, gestureType: GestureType.tripleTap);

  TripleTap.key(String key, {super.context})
    : super._(widgetKey: key, gestureType: GestureType.tripleTap);

  TripleTap.widget(String text, {super.context})
    : super._(widgetText: text, gestureType: GestureType.tripleTap);
}

class LongPress extends TapAction {
  LongPress.text(String text, {super.context})
    : super._(widgetText: text, gestureType: GestureType.longPress);

  LongPress.key(String key, {super.context})
    : super._(widgetKey: key, gestureType: GestureType.longPress);

  LongPress.widget(String text, {super.context})
    : super._(widgetText: text, gestureType: GestureType.longPress);
}
