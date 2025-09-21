import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../step_result.dart';
import '../../test_action.dart';

/// Swipe gestures for testing
class Swipe extends TestAction {
  final SwipeDirection direction;
  final double? distance;
  final String? targetKey;
  final String? targetText;
  final Type? targetType;
  final Duration duration;
  final SwipeContext? context;
  final Offset? startPoint;
  final Offset? endPoint;

  const Swipe._({
    required this.direction,
    this.distance,
    this.targetKey,
    this.targetText,
    this.targetType,
    this.duration = const Duration(milliseconds: 300),
    this.context,
    this.startPoint,
    this.endPoint,
  });

  /// Swipe up on widget or screen
  factory Swipe.up({
    String? onText,
    String? onKey,
    Type? onType,
    double distance = 300.0,
    Duration? duration,
  }) {
    return Swipe._(
      direction: SwipeDirection.up,
      targetText: onText,
      targetKey: onKey,
      targetType: onType,
      distance: distance,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Swipe down on widget or screen
  factory Swipe.down({
    String? onText,
    String? onKey,
    Type? onType,
    double distance = 300.0,
    Duration? duration,
  }) {
    return Swipe._(
      direction: SwipeDirection.down,
      targetText: onText,
      targetKey: onKey,
      targetType: onType,
      distance: distance,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Swipe left on widget or screen
  factory Swipe.left({
    String? onText,
    String? onKey,
    Type? onType,
    double distance = 300.0,
    Duration? duration,
  }) {
    return Swipe._(
      direction: SwipeDirection.left,
      targetText: onText,
      targetKey: onKey,
      targetType: onType,
      distance: distance,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Swipe right on widget or screen
  factory Swipe.right({
    String? onText,
    String? onKey,
    Type? onType,
    double distance = 300.0,
    Duration? duration,
  }) {
    return Swipe._(
      direction: SwipeDirection.right,
      targetText: onText,
      targetKey: onKey,
      targetType: onType,
      distance: distance,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Custom swipe from point to point
  factory Swipe.fromTo({
    required Offset from,
    required Offset to,
    Duration? duration,
  }) {
    return Swipe._(
      direction: SwipeDirection.custom,
      startPoint: from,
      endPoint: to,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Swipe to dismiss (commonly used for dismissible items)
  factory Swipe.toDismiss({
    String? itemText,
    String? itemKey,
    Type? itemType,
    SwipeDirection direction = SwipeDirection.left,
    Duration? duration,
  }) {
    return Swipe._(
      direction: direction,
      targetText: itemText,
      targetKey: itemKey,
      targetType: itemType,
      distance: 500.0, // Longer distance for dismiss
      duration: duration ?? const Duration(milliseconds: 300),
      context: SwipeContext._(isDismiss: true),
    );
  }

  /// Add context for widget disambiguation
  Swipe onWidget(String widgetDescription) {
    return Swipe._(
      direction: direction,
      distance: distance,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      duration: duration,
      startPoint: startPoint,
      endPoint: endPoint,
      context: SwipeContext._(widgetDescription: widgetDescription),
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (startPoint != null && endPoint != null) {
        // Custom swipe from point to point
        await _performCustomSwipe(tester);
      } else {
        // Direction-based swipe
        await _performDirectionalSwipe(tester);
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
        'Swipe failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<void> _performCustomSwipe(WidgetTester tester) async {
    await tester.timedDrag(
      find.byType(MaterialApp), // Use app as fallback
      endPoint! - startPoint!,
      duration,
      pointer: 1,
    );
  }

  Future<void> _performDirectionalSwipe(WidgetTester tester) async {
    Finder targetFinder;

    if (targetKey != null) {
      targetFinder = find.byKey(Key(targetKey!));
    } else if (targetText != null) {
      targetFinder = find.text(targetText!);
    } else if (targetType != null) {
      targetFinder = find.byType(targetType!);
    } else {
      // Swipe on entire screen
      targetFinder = find.byType(MaterialApp).first;
    }

    // Handle multiple matches
    if (targetFinder != find.byType(MaterialApp).first &&
        tester.widgetList(targetFinder).length > 1) {
      if (context?.widgetDescription != null) {
        // For now, use first match - in real implementation,
        // you'd add logic to find by context
        targetFinder = targetFinder.first;
      } else {
        targetFinder = targetFinder.first;
      }
    }

    Offset swipeOffset = _getSwipeOffset();

    if (context?.isDismiss == true) {
      // For dismiss, we need to ensure the swipe goes far enough
      await tester.timedDrag(targetFinder, swipeOffset, duration);
    } else {
      await tester.timedDrag(targetFinder, swipeOffset, duration);
    }
  }

  Offset _getSwipeOffset() {
    final swipeDistance = distance ?? 300.0;

    switch (direction) {
      case SwipeDirection.up:
        return Offset(0, -swipeDistance);
      case SwipeDirection.down:
        return Offset(0, swipeDistance);
      case SwipeDirection.left:
        return Offset(-swipeDistance, 0);
      case SwipeDirection.right:
        return Offset(swipeDistance, 0);
      case SwipeDirection.custom:
        return Offset.zero; // Not used for custom swipes
    }
  }

  String _getSuccessMessage() {
    if (startPoint != null && endPoint != null) {
      return 'Swiped from $startPoint to $endPoint';
    }

    String target =
        targetText ?? targetKey ?? targetType?.toString() ?? 'screen';
    String directionStr = direction.toString().split('.').last;

    if (context?.isDismiss == true) {
      return 'Swiped to dismiss $target';
    }

    return 'Swiped $directionStr on $target';
  }

  @override
  String get description => _getSuccessMessage();
}

enum SwipeDirection { up, down, left, right, custom }

class SwipeContext {
  final String? widgetDescription;
  final bool isDismiss;

  const SwipeContext._({this.widgetDescription, this.isDismiss = false});
}
