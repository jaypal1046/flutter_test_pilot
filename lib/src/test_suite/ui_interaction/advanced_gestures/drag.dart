// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../step_result.dart';
import '../../test_action.dart';

/// Drag and drop gestures for testing
class DragDrop extends TestAction {
  final String? fromText;
  final String? fromKey;
  final Type? fromType;
  final String? toText;
  final String? toKey;
  final Type? toType;
  final Offset? fromPoint;
  final Offset? toPoint;
  final Offset? byOffset;
  final Duration duration;
  final DragDropContext? context;
  final bool waitForLongPress;

  const DragDrop._({
    this.fromText,
    this.fromKey,
    this.fromType,
    this.toText,
    this.toKey,
    this.toType,
    this.fromPoint,
    this.toPoint,
    this.byOffset,
    this.duration = const Duration(milliseconds: 600),
    this.context,
    this.waitForLongPress = false,
  });

  /// DragDrop from one widget to another by text
  factory DragDrop.fromTo({
    String? fromText,
    String? fromKey,
    Type? fromType,
    String? toText,
    String? toKey,
    Type? toType,
    Duration? duration,
    bool waitForLongPress = false,
  }) {
    return DragDrop._(
      fromText: fromText,
      fromKey: fromKey,
      fromType: fromType,
      toText: toText,
      toKey: toKey,
      toType: toType,
      duration: duration ?? const Duration(milliseconds: 600),
      waitForLongPress: waitForLongPress,
    );
  }

  /// DragDrop widget by offset
  factory DragDrop.byOffset({
    String? fromText,
    String? fromKey,
    Type? fromType,
    required Offset offset,
    Duration? duration,
    bool waitForLongPress = false,
  }) {
    return DragDrop._(
      fromText: fromText,
      fromKey: fromKey,
      fromType: fromType,
      byOffset: offset,
      duration: duration ?? const Duration(milliseconds: 600),
      waitForLongPress: waitForLongPress,
    );
  }

  /// Drag from point to point (screen coordinates)
  factory DragDrop.fromPointToPoint({
    required Offset from,
    required Offset to,
    Duration? duration,
    bool waitForLongPress = false,
  }) {
    return DragDrop._(
      fromPoint: from,
      toPoint: to,
      duration: duration ?? const Duration(milliseconds: 600),
      waitForLongPress: waitForLongPress,
    );
  }

  /// DragDrop and drop for reordering (like in ReorderableListView)
  factory DragDrop.toReorder({
    required String itemText,
    required int fromIndex,
    required int toIndex,
    Duration? duration,
  }) {
    return DragDrop._(
      fromText: itemText,
      duration: duration ?? const Duration(milliseconds: 600),
      context: DragDropContext._(
        isReorder: true,
        fromIndex: fromIndex,
        toIndex: toIndex,
      ),
      waitForLongPress: true, // Reorder usually requires long press
    );
  }

  /// DragDrop to specific position (like slider)
  factory DragDrop.toPosition({
    String? sliderText,
    String? sliderKey,
    Type? sliderType,
    required double position, // 0.0 to 1.0
    Duration? duration,
  }) {
    return DragDrop._(
      fromText: sliderText,
      fromKey: sliderKey,
      fromType: sliderType,
      duration: duration ?? const Duration(milliseconds: 600),
      context: DragDropContext._(isSlider: true, targetPosition: position),
    );
  }

  /// Add context for disambiguation
  DragDrop withContext(String description) {
    return DragDrop._(
      fromText: fromText,
      fromKey: fromKey,
      fromType: fromType,
      toText: toText,
      toKey: toKey,
      toType: toType,
      fromPoint: fromPoint,
      toPoint: toPoint,
      byOffset: byOffset,
      duration: duration,
      waitForLongPress: waitForLongPress,
      context: DragDropContext._(contextDescription: description),
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (context?.isReorder == true) {
        await _performReorderDrag(tester);
      } else if (context?.isSlider == true) {
        await _performSliderDrag(tester);
      } else if (fromPoint != null && toPoint != null) {
        await _performPointToPointDrag(tester);
      } else if (byOffset != null) {
        await _performOffsetDrag(tester);
      } else {
        await _performWidgetToWidgetDrag(tester);
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      return StepResult.success(
        message: _getSuccessMessage(),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure('Drag failed: $e', duration: stopwatch.elapsed);
    }
  }

  Future<void> _performReorderDrag(WidgetTester tester) async {
    final itemFinder = _getFromFinder();

    if (waitForLongPress) {
      await tester.longPress(itemFinder);
      await tester.pump();
    }

    // Calculate drag distance based on item height and index difference
    final itemSize = tester.getSize(itemFinder);
    final indexDifference = context!.toIndex! - context!.fromIndex!;
    final dragDistance = itemSize.height * indexDifference;

    await tester.timedDrag(itemFinder, Offset(0, dragDistance), duration);
  }

  Future<void> _performSliderDrag(WidgetTester tester) async {
    final sliderFinder = _getFromFinder();
    final sliderRect = tester.getRect(sliderFinder);

    // Calculate target position on slider
    final targetX =
        sliderRect.left + (sliderRect.width * context!.targetPosition!);
    final targetOffset = Offset(targetX - sliderRect.center.dx, 0);

    await tester.timedDrag(sliderFinder, targetOffset, duration);
  }

  Future<void> _performPointToPointDrag(WidgetTester tester) async {
    final gesture = await tester.startGesture(fromPoint!);

    if (waitForLongPress) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    await gesture.moveTo(toPoint!);
    await gesture.up();
  }

  Future<void> _performOffsetDrag(WidgetTester tester) async {
    final fromFinder = _getFromFinder();

    if (waitForLongPress) {
      await tester.longPress(fromFinder);
      await tester.pump();
    }

    await tester.timedDrag(fromFinder, byOffset!, duration);
  }

  Future<void> _performWidgetToWidgetDrag(WidgetTester tester) async {
    final fromFinder = _getFromFinder();
    final toFinder = _getToFinder();

    // Validate that the finders match at least one widget
    if (fromFinder.evaluate().isEmpty) {
      throw Exception(
        'No widget found for fromFinder: ${fromText ?? fromKey ?? fromType}',
      );
    }
    if (toFinder.evaluate().isEmpty) {
      throw Exception(
        'No widget found for toFinder: ${toText ?? toKey ?? toType}',
      );
    }

    if (waitForLongPress) {
      await tester.longPress(fromFinder);
      await tester.pump();
    }

    // Use the timedDragFrom extension method
    await tester.customTimedDragFrom(fromFinder, toFinder, duration);
  }

  Finder _getFromFinder() {
    if (fromKey != null) {
      return find.byKey(Key(fromKey!));
    } else if (fromText != null) {
      return find.text(fromText!);
    } else if (fromType != null) {
      return find.byType(fromType!);
    } else {
      throw Exception('Must specify from widget for drag operation');
    }
  }

  Finder _getToFinder() {
    if (toKey != null) {
      return find.byKey(Key(toKey!));
    } else if (toText != null) {
      return find.text(toText!);
    } else if (toType != null) {
      return find.byType(toType!);
    } else {
      throw Exception('Must specify to widget for drag operation');
    }
  }

  String _getSuccessMessage() {
    if (context?.isReorder == true) {
      return 'Reordered "$fromText" from index ${context!.fromIndex} to ${context!.toIndex}';
    } else if (context?.isSlider == true) {
      return 'Dragged slider to position ${context!.targetPosition}';
    } else if (fromPoint != null && toPoint != null) {
      return 'Dragged from $fromPoint to $toPoint';
    } else if (byOffset != null) {
      String from = fromText ?? fromKey ?? fromType?.toString() ?? 'widget';
      return 'Dragged $from by offset $byOffset';
    } else {
      String from = fromText ?? fromKey ?? fromType?.toString() ?? 'source';
      String to = toText ?? toKey ?? toType?.toString() ?? 'target';
      return 'Dragged from $from to $to';
    }
  }

  @override
  String get description => _getSuccessMessage();
}

// Extension to add timedDragFrom method
extension WidgetTesterDragExtension on WidgetTester {
  Future<void> customTimedDragFrom(
    Finder from,
    Finder to,
    Duration duration,
  ) async {
    final fromCenter = getCenter(from);
    final toCenter = getCenter(to);
    final offset = toCenter - fromCenter;

    await timedDrag(from, offset, duration);
  }
}

class DragDropContext {
  final String? contextDescription;
  final bool isReorder;
  final bool isSlider;
  final int? fromIndex;
  final int? toIndex;
  final double? targetPosition;

  const DragDropContext._({
    this.contextDescription,
    this.isReorder = false,
    this.isSlider = false,
    this.fromIndex,
    this.toIndex,
    this.targetPosition,
  });
}
