import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../step_result.dart';
import '../../test_action.dart';
import 'dart:math' as math;

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

  // Enhanced properties
  final double tolerance;
  final int maxRetries;
  final Duration? startDelay;
  final bool waitForAnimation;
  final Function(Exception)? onError;
  final double angle; // Angle of pinch in radians
  final double minScale;
  final double maxScale;
  final double? velocity;

  const Pinch._({
    required this.type,
    this.scale,
    this.targetKey,
    this.targetText,
    this.targetType,
    this.center,
    this.duration = const Duration(milliseconds: 500),
    this.context,
    this.tolerance = 5.0,
    this.maxRetries = 1,
    this.startDelay,
    this.waitForAnimation = true,
    this.onError,
    this.angle = 0.0,
    this.minScale = 0.1,
    this.maxScale = 10.0,
    this.velocity,
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
    double tolerance = 5.0,
    int maxRetries = 1,
    Duration? startDelay,
    bool waitForAnimation = true,
    Function(Exception)? onError,
    double angle = 0.0,
    double minScale = 0.1,
    double maxScale = 10.0,
    double? velocity,
  }) {
    return Pinch._(
      type: PinchType.zoomIn,
      scale: math.min(scale, maxScale),
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      center: center,
      duration: duration ?? const Duration(milliseconds: 500),
      context: context,
      tolerance: tolerance,
      maxRetries: maxRetries,
      startDelay: startDelay,
      waitForAnimation: waitForAnimation,
      onError: onError,
      angle: angle,
      minScale: minScale,
      maxScale: maxScale,
      velocity: velocity,
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
    double tolerance = 5.0,
    int maxRetries = 1,
    Duration? startDelay,
    bool waitForAnimation = true,
    Function(Exception)? onError,
    double angle = 0.0,
    double minScale = 0.1,
    double maxScale = 10.0,
    double? velocity,
  }) {
    return Pinch._(
      type: PinchType.zoomOut,
      scale: math.max(scale, minScale),
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      center: center,
      duration: duration ?? const Duration(milliseconds: 500),
      context: context,
      tolerance: tolerance,
      maxRetries: maxRetries,
      startDelay: startDelay,
      waitForAnimation: waitForAnimation,
      onError: onError,
      angle: angle,
      minScale: minScale,
      maxScale: maxScale,
      velocity: velocity,
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
    double tolerance = 5.0,
    int maxRetries = 1,
    Duration? startDelay,
    bool waitForAnimation = true,
    Function(Exception)? onError,
    double angle = 0.0,
    double minScale = 0.1,
    double maxScale = 10.0,
    double? velocity,
  }) {
    // Clamp scale within bounds
    final clampedScale = math.max(minScale, math.min(scale, maxScale));

    return Pinch._(
      type: PinchType.toScale,
      scale: clampedScale,
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      center: center,
      duration: duration ?? const Duration(milliseconds: 500),
      context: context,
      tolerance: tolerance,
      maxRetries: maxRetries,
      startDelay: startDelay,
      waitForAnimation: waitForAnimation,
      onError: onError,
      angle: angle,
      minScale: minScale,
      maxScale: maxScale,
      velocity: velocity,
    );
  }

  /// Add context for disambiguation
  Pinch withContext(
    String pinchableDescription, {
    double? expectedScale,
    Rect? restrictedArea,
  }) {
    return Pinch._(
      type: type,
      scale: scale,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      center: center,
      duration: duration,
      context: PinchContext._(
        pinchableDescription: pinchableDescription,
        expectedScale: expectedScale,
        restrictedArea: restrictedArea,
      ),
      tolerance: tolerance,
      maxRetries: maxRetries,
      startDelay: startDelay,
      waitForAnimation: waitForAnimation,
      onError: onError,
      angle: angle,
      minScale: minScale,
      maxScale: maxScale,
      velocity: velocity,
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    int attempt = 0;

    while (attempt <= maxRetries) {
      try {
        // Apply start delay if specified
        if (startDelay != null) {
          await tester.pump(startDelay!);
        }

        // Wait for animations to complete before starting
        if (waitForAnimation) {
          await tester.pumpAndSettle();
        }

        await _performPinch(tester);

        // Wait for animations to complete after pinch
        if (waitForAnimation) {
          await tester.pumpAndSettle();
        }

        stopwatch.stop();

        return StepResult.success(
          message: _getSuccessMessage(),
          duration: stopwatch.elapsed,
        );
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) {
          stopwatch.stop();

          // Use custom error handler if provided
          if (onError != null) {
            try {
              onError!(e as Exception);
            } catch (handlerError) {
              return StepResult.failure(
                'Pinch failed after $maxRetries attempts: $e. Error handler also failed: $handlerError',
                duration: stopwatch.elapsed,
              );
            }
          }

          return StepResult.failure(
            'Pinch failed after $maxRetries attempts: $e',
            duration: stopwatch.elapsed,
          );
        }

        // Wait before retry
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    stopwatch.stop();
    return StepResult.failure(
      'Pinch failed: Unexpected end of retry loop',
      duration: stopwatch.elapsed,
    );
  }

  Future<void> _performPinch(WidgetTester tester) async {
    // Determine the center point for the pinch
    final pinchCenter = center ?? await _getTargetCenter(tester);

    // Validate pinch center is within screen bounds
    final screenSize =
        tester.binding.window.physicalSize /
        tester.binding.window.devicePixelRatio;
    if (pinchCenter.dx < 0 ||
        pinchCenter.dy < 0 ||
        pinchCenter.dx > screenSize.width ||
        pinchCenter.dy > screenSize.height) {
      throw Exception('Pinch center $pinchCenter is outside screen bounds');
    }

    // Define initial and final distances for the two pointers
    const double baseDistance = 50.0;
    double initialDistance;
    double finalDistance;

    // Calculate distances based on pinch type
    switch (type) {
      case PinchType.zoomIn:
        initialDistance = baseDistance;
        finalDistance = baseDistance * (scale ?? 2.0);
        break;
      case PinchType.zoomOut:
        initialDistance = baseDistance * (1.0 / (scale ?? 0.5));
        finalDistance = baseDistance;
        break;
      case PinchType.toScale:
        if (scale! > 1.0) {
          // Zooming in
          initialDistance = baseDistance;
          finalDistance = baseDistance * scale!;
        } else {
          // Zooming out
          initialDistance = baseDistance / scale!;
          finalDistance = baseDistance;
        }
        break;
    }

    // Calculate pointer positions with angle support
    final double cosAngle = math.cos(angle);
    final double sinAngle = math.sin(angle);

    final Offset pointer1Initial =
        pinchCenter +
        Offset(
          -initialDistance / 2 * cosAngle,
          -initialDistance / 2 * sinAngle,
        );
    final Offset pointer2Initial =
        pinchCenter +
        Offset(initialDistance / 2 * cosAngle, initialDistance / 2 * sinAngle);

    final Offset pointer1Final =
        pinchCenter +
        Offset(-finalDistance / 2 * cosAngle, -finalDistance / 2 * sinAngle);
    final Offset pointer2Final =
        pinchCenter +
        Offset(finalDistance / 2 * cosAngle, finalDistance / 2 * sinAngle);

    // Validate pointer positions are within bounds
    final targetRect = await _getTargetRect(tester);
    final effectiveArea = context?.restrictedArea ?? targetRect;
    _validatePointerBounds(pointer1Initial, pointer2Initial, effectiveArea);
    _validatePointerBounds(pointer1Final, pointer2Final, effectiveArea);

    // Start two pointers for the pinch gesture
    final gesture1 = await tester.startGesture(pointer1Initial);
    final gesture2 = await tester.startGesture(pointer2Initial);

    // Apply velocity if specified
    if (velocity != null) {
      final offset1 = pointer1Final - pointer1Initial;
      final offset2 = pointer2Final - pointer2Initial;

      await gesture1.moveBy(
        offset1,
        timeStamp: Duration(
          milliseconds: (offset1.distance / velocity!).round(),
        ),
      );
      await gesture2.moveBy(
        offset2,
        timeStamp: Duration(
          milliseconds: (offset2.distance / velocity!).round(),
        ),
      );
    } else {
      // Move pointers to final positions over the duration
      await Future.wait([
        gesture1.moveTo(pointer1Final, timeStamp: duration),
        gesture2.moveTo(pointer2Final, timeStamp: duration),
      ]);
    }

    // Release both pointers
    await gesture1.up();
    await gesture2.up();

    // Validate expected scale if provided in context
    if (context?.expectedScale != null) {
      await _validateExpectedScale(tester);
    }
  }

  void _validatePointerBounds(
    Offset pointer1,
    Offset pointer2,
    Rect targetRect,
  ) {
    // Expand bounds slightly to account for tolerance
    final expandedRect = targetRect.inflate(tolerance);

    if (!expandedRect.contains(pointer1) || !expandedRect.contains(pointer2)) {
      throw Exception(
        'Pinch pointers ($pointer1, $pointer2) exceed target bounds $expandedRect',
      );
    }
  }

  Future<void> _validateExpectedScale(WidgetTester tester) async {
    // This is a placeholder for scale validation
    // In real implementation, you'd check the actual scale of the target widget
    // For InteractiveViewer, you could check the transform matrix
    // For custom widgets, you'd need widget-specific scale checking

    final expectedScale = context!.expectedScale!;
    final actualScale = await _getCurrentScale(tester);

    if ((actualScale - expectedScale).abs() > tolerance) {
      throw Exception(
        'Expected scale $expectedScale but got $actualScale (tolerance: $tolerance)',
      );
    }
  }

  Future<double> _getCurrentScale(WidgetTester tester) async {
    final targetFinder = _getTargetFinder(tester);

    // Try to get scale from InteractiveViewer
    try {
      final interactiveViewerFinder = find.ancestor(
        of: targetFinder,
        matching: find.byType(InteractiveViewer),
      );

      if (interactiveViewerFinder.evaluate().isNotEmpty) {
        final interactiveViewer = tester.widget<InteractiveViewer>(
          interactiveViewerFinder.first,
        );

        // Get the current transformation matrix
        final controller = interactiveViewer.transformationController;
        if (controller != null) {
          final matrix = controller.value;
          // Extract scale from transformation matrix
          // The scale is the length of the first row vector (or column vector)
          final scaleX = math.sqrt(
            matrix.entry(0, 0) * matrix.entry(0, 0) +
                matrix.entry(1, 0) * matrix.entry(1, 0),
          );
          return scaleX;
        }

        // If no controller, try to get scale from Transform widget
        return _getTransformScale(tester, interactiveViewerFinder);
      }

      // Try to get scale from Transform widget
      return _getTransformScale(tester, targetFinder);
    } catch (e) {
      // Try alternative methods to get scale
      return _getAlternativeScale(tester, targetFinder);
    }
  }

  double _getTransformScale(WidgetTester tester, Finder finder) {
    try {
      final transformFinder = find.ancestor(
        of: finder,
        matching: find.byType(Transform),
      );

      if (transformFinder.evaluate().isNotEmpty) {
        final transform = tester.widget<Transform>(transformFinder.first);
        final matrix = transform.transform;

        // Extract scale from transformation matrix
        final scaleX = math.sqrt(
          matrix.entry(0, 0) * matrix.entry(0, 0) +
              matrix.entry(1, 0) * matrix.entry(1, 0),
        );
        return scaleX;
      }

      return 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  double _getAlternativeScale(WidgetTester tester, Finder targetFinder) {
    try {
      // Get widget size before and after to calculate scale
      final currentSize = tester.getSize(targetFinder);

      // For some widgets, we can compare with their natural/expected size
      // This is widget-specific logic
      final widget = tester.widget(targetFinder);

      if (widget is Container && widget.constraints != null) {
        final expectedWidth = widget.constraints!.maxWidth;
        if (expectedWidth.isFinite) {
          return currentSize.width / expectedWidth;
        }
      }

      // If we can't determine scale, assume no scaling
      return 1.0;
    } catch (e) {
      return 1.0;
    }
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

  Future<Rect> _getTargetRect(WidgetTester tester) async {
    final targetFinder = _getTargetFinder(tester);
    if (targetFinder.evaluate().isEmpty) {
      throw Exception(
        'No target widget found for pinch: ${targetText ?? targetKey ?? targetType}',
      );
    }
    return tester.getRect(targetFinder);
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
    final retryInfo = maxRetries > 0 && maxRetries > 1
        ? ' (completed after retries)'
        : '';
    final target =
        targetText ?? targetKey ?? targetType?.toString() ?? 'screen';

    if (type == PinchType.zoomIn) {
      return 'Zoomed in on $target by scale ${scale ?? 2.0}$retryInfo';
    } else if (type == PinchType.zoomOut) {
      return 'Zoomed out on $target by scale ${scale ?? 0.5}$retryInfo';
    } else {
      return 'Pinched to scale $scale on $target$retryInfo';
    }
  }

  @override
  String get description => _getSuccessMessage();
}

enum PinchType { zoomIn, zoomOut, toScale }

class PinchContext {
  final String? pinchableDescription;
  final double? expectedScale;
  final Rect? restrictedArea;

  const PinchContext._({
    this.pinchableDescription,
    this.expectedScale,
    this.restrictedArea,
  });
}
