import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../step_result.dart';
import '../../../test_action.dart';

/// Pinch gesture for zoom operations
class Pinch extends TestAction {
  final PinchType type;
  final double? scale;
  final String? targetKey;
  final String? targetText;
  final Type? targetType;
  final Offset? center;
  final Duration duration;
  final PinchContext? context;

  const Pinch._({
    required this.type,
    this.scale,
    this.targetKey,
    this.targetText,
    this.targetType,
    this.center,
    this.duration = const Duration(milliseconds: 500),
    this.context,
  });

  /// Pinch to zoom in
  factory Pinch.zoomIn({
    double scale = 2.0,
    String? onText,
    String? onKey,
    Type? onType,
    Offset? center,
    Duration? duration,
    PinchContext? context,
  }) {
    return Pinch._(
      type: PinchType.zoomIn,
      scale: scale,
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      center: center,
      duration: duration ?? const Duration(milliseconds: 500),
      context: context,
    );
  }

  /// Pinch to zoom out
  factory Pinch.zoomOut({
    double scale = 0.5,
    String? onText,
    String? onKey,
    Type? onType,
    Offset? center,
    Duration? duration,
    PinchContext? context,
  }) {
    return Pinch._(
      type: PinchType.zoomOut,
      scale: scale,
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      center: center,
      duration: duration ?? const Duration(milliseconds: 500),
      context: context,
    );
  }

  /// Pinch to specific scale
  factory Pinch.toScale({
    required double scale,
    String? onText,
    String? onKey,
    Type? onType,
    Offset? center,
    Duration? duration,
    PinchContext? context,
  }) {
    return Pinch._(
      type: PinchType.toScale,
      scale: scale,
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      center: center,
      duration: duration ?? const Duration(milliseconds: 500),
      context: context,
    );
  }

  /// Add context for disambiguation
  Pinch withContext(String pinchableDescription) {
    return Pinch._(
      type: type,
      scale: scale,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      center: center,
      duration: duration,
      context: PinchContext._(pinchableDescription: pinchableDescription),
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      await _performPinch(tester);
      await tester.pumpAndSettle();
      stopwatch.stop();

      return StepResult.success(
        message: _getSuccessMessage(),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Pinch failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<void> _performPinch(WidgetTester tester) async {
    // Determine the center point for the pinch
    final pinchCenter = center ?? await _getTargetCenter(tester);

    // Define initial and final distances for the two pointers
    const initialDistance = 50.0; // Initial distance between pointers
    final finalDistance = scale != null
        ? initialDistance * scale!
        : initialDistance;

    // Calculate pointer positions
    final Offset pointer1Initial =
        pinchCenter + Offset(-initialDistance / 2, 0);
    final Offset pointer2Initial = pinchCenter + Offset(initialDistance / 2, 0);
    final Offset pointer1Final;
    final Offset pointer2Final;

    if (type == PinchType.zoomIn) {
      // Move pointers apart to zoom in
      pointer1Final = pinchCenter + Offset(-finalDistance / 2, 0);
      pointer2Final = pinchCenter + Offset(finalDistance / 2, 0);
    } else if (type == PinchType.zoomOut) {
      // Move pointers together to zoom out
      pointer1Final = pinchCenter + Offset(-finalDistance / 2, 0);
      pointer2Final = pinchCenter + Offset(finalDistance / 2, 0);
    } else {
      // toScale uses the provided scale directly
      pointer1Final = pinchCenter + Offset(-finalDistance / 2, 0);
      pointer2Final = pinchCenter + Offset(finalDistance / 2, 0);
    }

    // Start two pointers for the pinch gesture
    final gesture1 = await tester.startGesture(pointer1Initial);
    final gesture2 = await tester.startGesture(pointer2Initial);

    // Move pointers to final positions over the duration
    await Future.wait([
      gesture1.moveTo(pointer1Final, timeStamp: duration),
      gesture2.moveTo(pointer2Final, timeStamp: duration),
    ]);

    // Release both pointers
    await gesture1.up();
    await gesture2.up();
  }

  Future<Offset> _getTargetCenter(WidgetTester tester) async {
    final targetFinder = _getTargetFinder(tester);
    if (targetFinder.evaluate().isEmpty) {
      throw Exception(
        'No target widget found for pinch: ${targetText ?? targetKey ?? targetType}',
      );
    }
    return tester.getCenter(targetFinder);
  }

  Finder _getTargetFinder(WidgetTester tester) {
    if (targetKey != null) {
      return find.byKey(Key(targetKey!));
    } else if (targetText != null) {
      return find.text(targetText!);
    } else if (targetType != null) {
      return find.byType(targetType!);
    } else {
      // Default to finding a widget that can handle pinch (e.g., InteractiveViewer)
      final pinchables = [
        find.byType(InteractiveViewer),
        find.byType(Transform),
        find.byType(Scrollable),
      ];
      for (final finder in pinchables) {
        if (finder.evaluate().isNotEmpty) {
          return finder.first;
        }
      }
      throw Exception('No pinchable widget found');
    }
  }

  String _getSuccessMessage() {
    final target =
        targetText ?? targetKey ?? targetType?.toString() ?? 'screen';
    if (type == PinchType.zoomIn) {
      return 'Zoomed in on $target by scale ${scale ?? 2.0}';
    } else if (type == PinchType.zoomOut) {
      return 'Zoomed out on $target by scale ${scale ?? 0.5}';
    } else {
      return 'Pinched to scale $scale on $target';
    }
  }

  @override
  String get description => _getSuccessMessage();
}

enum PinchType { zoomIn, zoomOut, toScale }

class PinchContext {
  final String? pinchableDescription;

  const PinchContext._({this.pinchableDescription});
}

/// Pan gesture for dragging across a widget or screen
class Pan extends TestAction {
  final PanDirection? direction;
  final double? distance;
  final String? targetKey;
  final String? targetText;
  final Type? targetType;
  final Offset? byOffset;
  final Offset? center;
  final Duration duration;
  final PanContext? context;

  const Pan._({
    this.direction,
    this.distance,
    this.targetKey,
    this.targetText,
    this.targetType,
    this.byOffset,
    this.center,
    this.duration = const Duration(milliseconds: 300),
    this.context,
  });

  /// Pan in a specific direction
  factory Pan.inDirection({
    required PanDirection direction,
    double distance = 100.0,
    String? onText,
    String? onKey,
    Type? onType,
    Duration? duration,
    PanContext? context,
  }) {
    return Pan._(
      direction: direction,
      distance: distance,
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      duration: duration ?? const Duration(milliseconds: 300),
      context: context,
    );
  }

  /// Pan by specific offset
  factory Pan.byOffset({
    required Offset offset,
    String? onText,
    String? onKey,
    Type? onType,
    Duration? duration,
    PanContext? context,
  }) {
    return Pan._(
      byOffset: offset,
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      duration: duration ?? const Duration(milliseconds: 300),
      context: context,
    );
  }

  /// Add context for disambiguation
  Pan withContext(String pannableDescription) {
    return Pan._(
      direction: direction,
      distance: distance,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      byOffset: byOffset,
      center: center,
      duration: duration,
      context: PanContext._(pannableDescription: pannableDescription),
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      await _performPan(tester);
      await tester.pumpAndSettle();
      stopwatch.stop();

      return StepResult.success(
        message: _getSuccessMessage(),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure('Pan failed: $e', duration: stopwatch.elapsed);
    }
  }

  Future<void> _performPan(WidgetTester tester) async {
    final targetFinder = _getTargetFinder(tester);
    if (targetFinder.evaluate().isEmpty) {
      throw Exception(
        'No target widget found for pan: ${targetText ?? targetKey ?? targetType}',
      );
    }
    final panCenter = center ?? tester.getCenter(targetFinder);

    Offset panOffset;
    if (byOffset != null) {
      panOffset = byOffset!;
    } else if (direction != null && distance != null) {
      switch (direction!) {
        case PanDirection.up:
          panOffset = Offset(0, -distance!);
          break;
        case PanDirection.down:
          panOffset = Offset(0, distance!);
          break;
        case PanDirection.left:
          panOffset = Offset(-distance!, 0);
          break;
        case PanDirection.right:
          panOffset = Offset(distance!, 0);
          break;
      }
    } else {
      throw Exception('Invalid pan configuration');
    }

    // Start the gesture at panCenter and move by panOffset
    final gesture = await tester.startGesture(panCenter);
    await gesture.moveBy(panOffset, timeStamp: duration);
    await gesture.up();
  }

  Finder _getTargetFinder(WidgetTester tester) {
    if (targetKey != null) {
      return find.byKey(Key(targetKey!));
    } else if (targetText != null) {
      return find.text(targetText!);
    } else if (targetType != null) {
      return find.byType(targetType!);
    } else {
      // Default to finding a pannable widget (e.g., InteractiveViewer, Scrollable)
      final pannables = [
        find.byType(InteractiveViewer),
        find.byType(Scrollable),
      ];
      for (final finder in pannables) {
        if (finder.evaluate().isNotEmpty) {
          return finder.first;
        }
      }
      throw Exception('No pannable widget found');
    }
  }

  String _getSuccessMessage() {
    final target =
        targetText ?? targetKey ?? targetType?.toString() ?? 'screen';
    if (byOffset != null) {
      return 'Panned $target by offset $byOffset';
    } else {
      return 'Panned $target ${direction.toString().split('.').last} by $distance';
    }
  }

  @override
  String get description => _getSuccessMessage();
}

enum PanDirection { up, down, left, right }

class PanContext {
  final String? pannableDescription;

  const PanContext._({this.pannableDescription});
}
