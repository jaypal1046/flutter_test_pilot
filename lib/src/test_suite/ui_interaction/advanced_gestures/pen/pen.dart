import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../step_result.dart';
import '../../../test_action.dart';
import 'dart:math' as math;

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

  // Enhanced properties
  final double tolerance;
  final int maxRetries;
  final Duration? startDelay;
  final bool waitForAnimation;
  final Function(Exception)? onError;
  final bool boundaryCheck;
  final double? velocity;
  final bool enableInertia;
  final Rect? restrictedArea;

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
    this.tolerance = 5.0,
    this.maxRetries = 1,
    this.startDelay,
    this.waitForAnimation = true,
    this.onError,
    this.boundaryCheck = true,
    this.velocity,
    this.enableInertia = false,
    this.restrictedArea,
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
    double tolerance = 5.0,
    int maxRetries = 1,
    Duration? startDelay,
    bool waitForAnimation = true,
    Function(Exception)? onError,
    bool boundaryCheck = true,
    double? velocity,
    bool enableInertia = false,
    Rect? restrictedArea,
  }) {
    return Pan._(
      direction: direction,
      distance: distance,
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      duration: duration ?? const Duration(milliseconds: 300),
      context: context,
      tolerance: tolerance,
      maxRetries: maxRetries,
      startDelay: startDelay,
      waitForAnimation: waitForAnimation,
      onError: onError,
      boundaryCheck: boundaryCheck,
      velocity: velocity,
      enableInertia: enableInertia,
      restrictedArea: restrictedArea,
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
    double tolerance = 5.0,
    int maxRetries = 1,
    Duration? startDelay,
    bool waitForAnimation = true,
    Function(Exception)? onError,
    bool boundaryCheck = true,
    double? velocity,
    bool enableInertia = false,
    Rect? restrictedArea,
  }) {
    return Pan._(
      byOffset: offset,
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      duration: duration ?? const Duration(milliseconds: 300),
      context: context,
      tolerance: tolerance,
      maxRetries: maxRetries,
      startDelay: startDelay,
      waitForAnimation: waitForAnimation,
      onError: onError,
      boundaryCheck: boundaryCheck,
      velocity: velocity,
      enableInertia: enableInertia,
      restrictedArea: restrictedArea,
    );
  }

  /// Fling pan with momentum
  factory Pan.fling({
    required PanDirection direction,
    double velocity = 1000.0,
    String? onText,
    String? onKey,
    Type? onType,
    PanContext? context,
    double tolerance = 5.0,
    int maxRetries = 1,
    Duration? startDelay,
    bool waitForAnimation = true,
    Function(Exception)? onError,
    bool boundaryCheck = true,
    Rect? restrictedArea,
  }) {
    return Pan._(
      direction: direction,
      distance: 100.0, // Base distance for fling
      targetKey: onKey,
      targetText: onText,
      targetType: onType,
      duration: const Duration(milliseconds: 100), // Short duration for fling
      context: context,
      tolerance: tolerance,
      maxRetries: maxRetries,
      startDelay: startDelay,
      waitForAnimation: waitForAnimation,
      onError: onError,
      boundaryCheck: boundaryCheck,
      velocity: velocity,
      enableInertia: true,
      restrictedArea: restrictedArea,
    );
  }

  /// Add context for disambiguation
  Pan withContext(
    String pannableDescription, {
    Rect? expectedBounds,
    double? expectedVelocity,
  }) {
    return Pan._(
      direction: direction,
      distance: distance,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      byOffset: byOffset,
      center: center,
      duration: duration,
      context: PanContext._(
        pannableDescription: pannableDescription,
        expectedBounds: expectedBounds,
        expectedVelocity: expectedVelocity,
      ),
      tolerance: tolerance,
      maxRetries: maxRetries,
      startDelay: startDelay,
      waitForAnimation: waitForAnimation,
      onError: onError,
      boundaryCheck: boundaryCheck,
      velocity: velocity,
      enableInertia: enableInertia,
      restrictedArea: restrictedArea,
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

        await _performPan(tester);

        // Wait for animations to complete after pan
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
                'Pan failed after $maxRetries attempts: $e. Error handler also failed: $handlerError',
                duration: stopwatch.elapsed,
              );
            }
          }

          return StepResult.failure(
            'Pan failed after $maxRetries attempts: $e',
            duration: stopwatch.elapsed,
          );
        }

        // Wait before retry
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    stopwatch.stop();
    return StepResult.failure(
      'Pan failed: Unexpected end of retry loop',
      duration: stopwatch.elapsed,
    );
  }

  Future<void> _performPan(WidgetTester tester) async {
    final targetFinder = _getTargetFinder(tester);
    if (targetFinder.evaluate().isEmpty) {
      throw Exception(
        'No target widget found for pan: ${targetText ?? targetKey ?? targetType}',
      );
    }

    final panCenter = center ?? tester.getCenter(targetFinder);
    final targetRect = tester.getRect(targetFinder);

    Offset panOffset = _calculatePanOffset();

    // Boundary checking
    if (boundaryCheck) {
      final effectiveArea =
          restrictedArea ?? context?.expectedBounds ?? targetRect;
      panOffset = _clampOffsetToBounds(panCenter, panOffset, effectiveArea);
    }

    if (velocity != null && enableInertia) {
      // Use fling for momentum-based panning
      await tester.flingFrom(panCenter, panOffset, velocity!);
    } else if (velocity != null) {
      // Use velocity-based drag without inertia
      final scaledDuration = Duration(
        milliseconds: (panOffset.distance / velocity! * 1000).round(),
      );
      await _performTimedPan(tester, panCenter, panOffset, scaledDuration);
    } else {
      // Standard timed pan
      await _performTimedPan(tester, panCenter, panOffset, duration);
    }

    // Validate expected velocity if provided in context
    if (context?.expectedVelocity != null && velocity != null) {
      _validateExpectedVelocity();
    }
  }

  void _validateExpectedVelocity() {
    final expectedVelocity = context!.expectedVelocity!;
    final actualVelocity = velocity!;

    if ((actualVelocity - expectedVelocity).abs() > tolerance) {
      throw Exception(
        'Expected velocity $expectedVelocity but used $actualVelocity (tolerance: $tolerance)',
      );
    }
  }

  Offset _calculatePanOffset() {
    if (byOffset != null) {
      return byOffset!;
    } else if (direction != null && distance != null) {
      switch (direction!) {
        case PanDirection.up:
          return Offset(0, -distance!);
        case PanDirection.down:
          return Offset(0, distance!);
        case PanDirection.left:
          return Offset(-distance!, 0);
        case PanDirection.right:
          return Offset(distance!, 0);
        case PanDirection.upLeft:
          return Offset(
            -distance! * 0.707,
            -distance! * 0.707,
          ); // 45 degree diagonal
        case PanDirection.upRight:
          return Offset(distance! * 0.707, -distance! * 0.707);
        case PanDirection.downLeft:
          return Offset(-distance! * 0.707, distance! * 0.707);
        case PanDirection.downRight:
          return Offset(distance! * 0.707, distance! * 0.707);
      }
    } else {
      throw Exception(
        'Invalid pan configuration: must specify either byOffset or direction with distance',
      );
    }
  }

  Offset _clampOffsetToBounds(Offset center, Offset offset, Rect bounds) {
    final destination = center + offset;

    // Clamp destination within bounds
    final clampedDestination = Offset(
      math.max(
        bounds.left + tolerance,
        math.min(bounds.right - tolerance, destination.dx),
      ),
      math.max(
        bounds.top + tolerance,
        math.min(bounds.bottom - tolerance, destination.dy),
      ),
    );

    return clampedDestination - center;
  }

  Future<void> _performTimedPan(
    WidgetTester tester,
    Offset center,
    Offset offset,
    Duration panDuration,
  ) async {
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(offset, timeStamp: panDuration);
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
        find.byType(PageView),
        find.byType(SingleChildScrollView),
        find.byType(ListView),
        find.byType(GridView),
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
    final retryInfo = maxRetries > 0 && maxRetries > 1
        ? ' (completed after retries)'
        : '';
    final target =
        targetText ?? targetKey ?? targetType?.toString() ?? 'screen';

    if (byOffset != null) {
      return 'Panned $target by offset $byOffset$retryInfo';
    } else if (enableInertia) {
      return 'Flung $target ${direction.toString().split('.').last} with velocity $velocity$retryInfo';
    } else {
      return 'Panned $target ${direction.toString().split('.').last} by $distance$retryInfo';
    }
  }

  @override
  String get description => _getSuccessMessage();
}

enum PanDirection {
  up,
  down,
  left,
  right,
  upLeft,
  upRight,
  downLeft,
  downRight, // Diagonal support
}

class PanContext {
  final String? pannableDescription;
  final Rect? expectedBounds;
  final double? expectedVelocity;

  const PanContext._({
    this.pannableDescription,
    this.expectedBounds,
    this.expectedVelocity,
  });
}
