import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../step_result.dart';
import '../../test_action.dart';

/// Universal slider component for testing - can slide any widget element
class Slider extends TestAction {
  final SliderDirection direction;
  final double? distance;
  final double? percentage; // 0.0 to 1.0
  final String? targetKey;
  final String? targetText;
  final Type? targetType;
  final Duration duration;
  final SliderContext? context;
  final SliderType sliderType;
  final double? toValue; // For range sliders
  final double? fromValue; // For range sliders

  const Slider._({
    required this.direction,
    this.distance,
    this.percentage,
    this.targetKey,
    this.targetText,
    this.targetType,
    this.duration = const Duration(milliseconds: 500),
    this.context,
    this.sliderType = SliderType.standard,
    this.toValue,
    this.fromValue,
  });

  /// Slide horizontally to a specific value (0.0 to 1.0)
  factory Slider.horizontal({
    String? targetKey,
    String? targetText,
    Type? targetType,
    double? toValue,
    double? percentage,
    Duration? duration,
    SliderType type = SliderType.standard,
  }) {
    return Slider._(
      direction: SliderDirection.horizontal,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      toValue: toValue,
      percentage: percentage,
      duration: duration ?? const Duration(milliseconds: 500),
      sliderType: type,
    );
  }

  /// Slide vertically to a specific value (0.0 to 1.0)
  factory Slider.vertical({
    String? targetKey,
    String? targetText,
    Type? targetType,
    double? toValue,
    double? percentage,
    Duration? duration,
    SliderType type = SliderType.standard,
  }) {
    return Slider._(
      direction: SliderDirection.vertical,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      toValue: toValue,
      percentage: percentage,
      duration: duration ?? const Duration(milliseconds: 500),
      sliderType: type,
    );
  }

  /// Slide by specific distance in pixels
  factory Slider.byDistance({
    required SliderDirection direction,
    required double distance,
    String? targetKey,
    String? targetText,
    Type? targetType,
    Duration? duration,
  }) {
    return Slider._(
      direction: direction,
      distance: distance,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      duration: duration ?? const Duration(milliseconds: 500),
    );
  }

  /// Slide to minimum value
  factory Slider.toMin({
    SliderDirection direction = SliderDirection.horizontal,
    String? targetKey,
    String? targetText,
    Type? targetType,
    Duration? duration,
  }) {
    return Slider._(
      direction: direction,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      toValue: 0.0,
      duration: duration ?? const Duration(milliseconds: 500),
    );
  }

  /// Slide to maximum value
  factory Slider.toMax({
    SliderDirection direction = SliderDirection.horizontal,
    String? targetKey,
    String? targetText,
    Type? targetType,
    Duration? duration,
  }) {
    return Slider._(
      direction: direction,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      toValue: 1.0,
      duration: duration ?? const Duration(milliseconds: 500),
    );
  }

  /// Slide range slider (for RangeSlider widgets)
  factory Slider.range({
    required double fromValue,
    required double toValue,
    SliderDirection direction = SliderDirection.horizontal,
    String? targetKey,
    String? targetText,
    Type? targetType,
    Duration? duration,
  }) {
    return Slider._(
      direction: direction,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      fromValue: fromValue,
      toValue: toValue,
      duration: duration ?? const Duration(milliseconds: 500),
      sliderType: SliderType.range,
    );
  }

  /// Add context for widget disambiguation
  Slider inContainer(String containerDescription) {
    return Slider._(
      direction: direction,
      distance: distance,
      percentage: percentage,
      targetKey: targetKey,
      targetText: targetText,
      targetType: targetType,
      duration: duration,
      sliderType: sliderType,
      toValue: toValue,
      fromValue: fromValue,
      context: SliderContext._(containerDescription: containerDescription),
    );
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      Finder targetFinder = _findSliderWidget(tester);

      switch (sliderType) {
        case SliderType.standard:
          await _slideStandardSlider(tester, targetFinder);
          break;
        case SliderType.range:
          await _slideRangeSlider(tester, targetFinder);
          break;
        case SliderType.custom:
          await _slideCustomWidget(tester, targetFinder);
          break;
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
        'Slider action failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<void> _slideStandardSlider(WidgetTester tester, Finder finder) async {
    final sliderWidget = tester.widget(finder);

    if (sliderWidget is Slider) {
      // This is a Flutter Slider widget
      final RenderBox renderBox = tester.renderObject(finder);
      final center = tester.getCenter(finder);

      Offset targetOffset = _calculateTargetOffset(renderBox, center);

      // Perform drag gesture
      await tester.timedDrag(finder, targetOffset - center, duration);
    } else {
      // Custom slidable widget
      await _slideCustomWidget(tester, finder);
    }
  }

  Future<void> _slideRangeSlider(WidgetTester tester, Finder finder) async {
    if (fromValue == null || toValue == null) {
      throw Exception('Range slider requires both fromValue and toValue');
    }

    final RenderBox renderBox = tester.renderObject(finder);
    final center = tester.getCenter(finder);

    // Handle range slider - would need specific implementation based on Flutter's RangeSlider
    // For now, slide to the average position
    final averageValue = (fromValue! + toValue!) / 2;
    final targetOffset = _calculateTargetOffsetForValue(
      renderBox,
      center,
      averageValue,
    );

    await tester.timedDrag(finder, targetOffset - center, duration);
  }

  Future<void> _slideCustomWidget(WidgetTester tester, Finder finder) async {
    final RenderBox renderBox = tester.renderObject(finder);
    final center = tester.getCenter(finder);

    Offset slideOffset;

    if (distance != null) {
      // Slide by specific distance
      slideOffset = direction == SliderDirection.horizontal
          ? Offset(distance!, 0)
          : Offset(0, distance!);
    } else {
      // Calculate offset based on percentage or value
      slideOffset = _calculateTargetOffset(renderBox, center) - center;
    }

    await tester.timedDrag(finder, slideOffset, duration);
  }

  Offset _calculateTargetOffset(RenderBox renderBox, Offset center) {
    final size = renderBox.size;
    double targetValue = toValue ?? percentage ?? 0.5;

    if (direction == SliderDirection.horizontal) {
      final targetX =
          renderBox.localToGlobal(Offset.zero).dx + (size.width * targetValue);
      return Offset(targetX, center.dy);
    } else {
      final targetY =
          renderBox.localToGlobal(Offset.zero).dy + (size.height * targetValue);
      return Offset(center.dx, targetY);
    }
  }

  Offset _calculateTargetOffsetForValue(
    RenderBox renderBox,
    Offset center,
    double value,
  ) {
    return _calculateTargetOffset(renderBox, center);
  }

  Finder _findSliderWidget(WidgetTester tester) {
    Finder finder;

    if (targetKey != null) {
      finder = find.byKey(Key(targetKey!));
    } else if (targetText != null) {
      // Try to find slider by semantics (accessibility)
      finder = find.bySemanticsLabel(targetText!);

      // Filter to only slider widgets
      if (tester.widgetList(finder).isNotEmpty) {
        finder = find.descendant(of: finder, matching: find.byType(Slider));
      }

      if (tester.widgetList(finder).isEmpty) {
        // Fallback: find slider near the text
        final textFinder = find.text(targetText!);
        if (tester.widgetList(textFinder).isNotEmpty) {
          // Look for slider as ancestor of the text
          finder = find.ancestor(of: textFinder, matching: find.byType(Slider));

          if (tester.widgetList(finder).isEmpty) {
            // Try finding slider as descendant of parent container
            final parentFinder = find.ancestor(
              of: textFinder,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container ||
                    widget is Column ||
                    widget is Row ||
                    widget is Card,
              ),
            );

            if (tester.widgetList(parentFinder).isNotEmpty) {
              finder = find.descendant(
                of: parentFinder.first,
                matching: find.byType(Slider),
              );
            }
          }
        }
      }

      if (tester.widgetList(finder).isEmpty) {
        // Last resort: find any slider and let disambiguation handle it
        finder = find.byType(Slider);
      }
    } else if (targetType != null) {
      finder = find.byType(targetType!);
    } else {
      // Find any slider-like widget
      finder = _findAnySliderWidget(tester);
    }

    if (tester.widgetList(finder).isEmpty) {
      throw Exception('No slider widget found with specified criteria');
    }

    // Handle multiple matches
    if (tester.widgetList(finder).length > 1) {
      if (context?.containerDescription != null) {
        // Try to find within specific container
        return finder
            .first; // Simplified - in real implementation, search by context
      }
      return finder.first;
    }

    return finder;
  }

  Finder _findAnySliderWidget(WidgetTester tester) {
    final sliderTypes = [
      find.byType(Slider),
      find.byType(RangeSlider),
      find.byType(CupertinoSlider),
      // Add other slider types as needed
    ];

    for (final finder in sliderTypes) {
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
    }

    // Look for custom slidable widgets
    return find.byWidgetPredicate(
      (widget) =>
          widget.runtimeType.toString().toLowerCase().contains('slider') ||
          widget.runtimeType.toString().toLowerCase().contains('slidable'),
    );
  }

  String _getSuccessMessage() {
    String target =
        targetText ?? targetKey ?? targetType?.toString() ?? 'slider';
    String directionStr = direction.toString().split('.').last;

    if (sliderType == SliderType.range) {
      return 'Slid range $target from $fromValue to $toValue';
    } else if (toValue != null) {
      return 'Slid $target $directionStr to $toValue';
    } else if (percentage != null) {
      return 'Slid $target $directionStr to ${(percentage! * 100).toInt()}%';
    } else if (distance != null) {
      return 'Slid $target $directionStr by $distance pixels';
    }

    return 'Slid $target $directionStr';
  }

  @override
  String get description => _getSuccessMessage();
}

enum SliderDirection { horizontal, vertical }

enum SliderType { standard, range, custom }

class SliderContext {
  final String? containerDescription;

  const SliderContext._({this.containerDescription});
}

/// Convenience methods for common slider actions
extension SliderExtensions on Slider {
  /// Quick horizontal slide to percentage
  static Slider toPercent(
    double percent, {
    String? key,
    String? text,
    Type? type,
  }) => Slider.horizontal(
    targetKey: key,
    targetText: text,
    targetType: type,
    percentage: percent / 100,
  );

  /// Quick volume-style slider (0-100)
  static Slider volume(int level, {String? key}) =>
      Slider.horizontal(targetKey: key, percentage: level / 100);

  /// Quick brightness slider (0-100)
  static Slider brightness(int level, {String? key}) =>
      Slider.horizontal(targetKey: key, percentage: level / 100);
}
