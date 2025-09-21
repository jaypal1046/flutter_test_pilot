import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../step_result.dart';
import '../../test_action.dart';

/// Scroll gestures for testing
class Scroll extends TestAction {
  final ScrollDirection? direction;
  final double? distance;
  final String? targetKey;
  final String? targetText;
  final Type? targetType;
  final ScrollPosition? position;
  final Duration duration;
  final ScrollContext? context;

  const Scroll._({
    this.direction,
    this.distance,
    this.targetKey,
    this.targetText,
    this.targetType,
    this.position,
    this.duration = const Duration(milliseconds: 300),
    this.context,
  });

  /// Scroll up by distance
  factory Scroll.up({double distance = 300.0, Duration? duration}) {
    return Scroll._(
      direction: ScrollDirection.up,
      distance: distance,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scroll down by distance
  factory Scroll.down({double distance = 300.0, Duration? duration}) {
    return Scroll._(
      direction: ScrollDirection.down,
      distance: distance,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scroll left by distance
  factory Scroll.left({double distance = 300.0, Duration? duration}) {
    return Scroll._(
      direction: ScrollDirection.left,
      distance: distance,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scroll right by distance
  factory Scroll.right({double distance = 300.0, Duration? duration}) {
    return Scroll._(
      direction: ScrollDirection.right,
      distance: distance,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scroll to specific position (0.0 to 1.0 where 1.0 is end)
  factory Scroll.to(double position, {Duration? duration}) {
    return Scroll._(
      position: ScrollPosition.relative(position),
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scroll to top
  factory Scroll.toTop({Duration? duration}) {
    return Scroll._(
      position: ScrollPosition.top(),
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scroll to bottom
  factory Scroll.toBottom({Duration? duration}) {
    return Scroll._(
      position: ScrollPosition.bottom(),
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scroll until widget is visible by text
  factory Scroll.untilVisible(
    String text, {
    Duration? duration,
    ScrollContext? context,
  }) {
    return Scroll._(
      targetText: text,
      duration: duration ?? const Duration(milliseconds: 300),
      context: context,
    );
  }

  /// Scroll until widget is visible by key
  factory Scroll.untilVisibleByKey(
    String key, {
    Duration? duration,
    ScrollContext? context,
  }) {
    return Scroll._(
      targetKey: key,
      duration: duration ?? const Duration(milliseconds: 300),
      context: context,
    );
  }

  /// Scroll until widget is visible by type
  factory Scroll.untilVisibleByType(
    Type type, {
    Duration? duration,
    ScrollContext? context,
  }) {
    return Scroll._(
      targetType: type,
      duration: duration ?? const Duration(milliseconds: 300),
      context: context,
    );
  }

  /// Add context for scrollable widget disambiguation
  Scroll inScrollable(String scrollableDescription) {
    return Scroll._(
      direction: direction,
      distance: distance,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      position: position,
      duration: duration,
      context: ScrollContext._(scrollableDescription: scrollableDescription),
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (targetText != null || targetKey != null || targetType != null) {
        // Scroll until visible
        await _scrollUntilVisible(tester);
      } else if (position != null) {
        // Scroll to position
        await _scrollToPosition(tester);
      } else if (direction != null && distance != null) {
        // Directional scroll
        await _scrollDirectional(tester);
      } else {
        throw Exception('Invalid scroll configuration');
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      return StepResult.success(
        message: _getSuccessMessage(),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Scroll failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<void> _scrollUntilVisible(WidgetTester tester) async {
    Finder targetFinder;

    if (targetKey != null) {
      targetFinder = find.byKey(Key(targetKey!));
    } else if (targetText != null) {
      targetFinder = find.text(targetText!);
    } else if (targetType != null) {
      targetFinder = find.byType(targetType!);
    } else {
      throw Exception('No target specified for scroll until visible');
    }

    // Find scrollable widget
    Finder scrollableFinder = _findScrollableWidget(tester);

    // Scroll until target is visible
    await tester.scrollUntilVisible(
      targetFinder,
      -200.0, // Default scroll delta
      scrollable: scrollableFinder,
      maxScrolls: 50,
    );
  }

  Future<void> _scrollToPosition(WidgetTester tester) async {
    final scrollableFinder = _findScrollableWidget(tester);
    final scrollableWidget = tester.widget(scrollableFinder);

    if (scrollableWidget is Scrollable) {
      final controller = scrollableWidget.controller;
      if (controller != null) {
        double targetPosition;

        if (position!.isRelative) {
          final maxExtent = controller.position.maxScrollExtent;
          targetPosition = maxExtent * position!.value;
        } else if (position!.isTop) {
          targetPosition = 0.0;
        } else if (position!.isBottom) {
          targetPosition = controller.position.maxScrollExtent;
        } else {
          targetPosition = position!.value;
        }

        await controller.animateTo(
          targetPosition,
          duration: duration,
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _scrollDirectional(WidgetTester tester) async {
    final scrollableFinder = _findScrollableWidget(tester);

    Offset scrollOffset;
    switch (direction!) {
      case ScrollDirection.up:
        scrollOffset = Offset(0, distance!);
        break;
      case ScrollDirection.down:
        scrollOffset = Offset(0, -distance!);
        break;
      case ScrollDirection.left:
        scrollOffset = Offset(distance!, 0);
        break;
      case ScrollDirection.right:
        scrollOffset = Offset(-distance!, 0);
        break;
    }

    await tester.drag(scrollableFinder, scrollOffset);
  }

  Finder _findScrollableWidget(WidgetTester tester) {
    if (context?.scrollableDescription != null) {
      // Try to find scrollable by description logic here
      // For now, return first scrollable
    }

    // Find first scrollable widget
    final scrollables = [
      find.byType(ListView),
      find.byType(GridView),
      find.byType(SingleChildScrollView),
      find.byType(CustomScrollView),
      find.byType(Scrollable),
    ];

    for (final finder in scrollables) {
      if (finder.evaluate().isNotEmpty) {
        return finder.first;
      }
    }

    throw Exception('No scrollable widget found');
  }

  String _getSuccessMessage() {
    if (targetText != null || targetKey != null || targetType != null) {
      return 'Scrolled until ${targetText ?? targetKey ?? targetType} is visible';
    } else if (position != null) {
      return 'Scrolled to position ${position!.value}';
    } else {
      return 'Scrolled ${direction.toString().split('.').last} by $distance';
    }
  }

  @override
  String get description => _getSuccessMessage();
}

enum ScrollDirection { up, down, left, right }

class ScrollPosition {
  final double value;
  final bool isRelative;
  final bool isTop;
  final bool isBottom;

  const ScrollPosition._(
    this.value, {
    this.isRelative = false,
    this.isTop = false,
    this.isBottom = false,
  });

  factory ScrollPosition.relative(double position) {
    assert(
      position >= 0.0 && position <= 1.0,
      'Relative position must be between 0.0 and 1.0',
    );
    return ScrollPosition._(position, isRelative: true);
  }

  factory ScrollPosition.absolute(double position) {
    return ScrollPosition._(position);
  }

  factory ScrollPosition.top() {
    return ScrollPosition._(0.0, isTop: true);
  }

  factory ScrollPosition.bottom() {
    return ScrollPosition._(0.0, isBottom: true);
  }
}

class ScrollContext {
  final String? scrollableDescription;

  const ScrollContext._({this.scrollableDescription});
}
