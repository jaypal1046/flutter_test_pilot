import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import '../step_result.dart';

/// Element verification utility to ensure widgets are ready for interaction
class ElementVerifier {
  static final ElementVerifier _instance = ElementVerifier._internal();
  static ElementVerifier get instance => _instance;

  ElementVerifier._internal();

  /// Verify element exists and is interactable
  Future<StepResult> verifyElement(
    WidgetTester tester,
    Finder finder, {
    String? elementName,
    Duration timeout = const Duration(seconds: 5),
    bool checkVisible = true,
    bool checkEnabled = true,
    bool checkHitTestable = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final name = elementName ?? 'Element';

    try {
      // Wait for element to exist
      final exists = await _waitForElement(tester, finder, timeout);
      if (!exists) {
        stopwatch.stop();
        return StepResult.failure(
          '$name not found within ${timeout.inSeconds}s',
          duration: stopwatch.elapsed,
        );
      }

      // Check if visible (on screen)
      if (checkVisible) {
        final isVisible = _isElementVisible(tester, finder);
        if (!isVisible) {
          stopwatch.stop();
          return StepResult.failure(
            '$name exists but is not visible on screen',
            duration: stopwatch.elapsed,
          );
        }
      }

      // Check if enabled
      if (checkEnabled) {
        final isEnabled = _isElementEnabled(tester, finder);
        if (!isEnabled) {
          stopwatch.stop();
          return StepResult.failure(
            '$name is disabled',
            duration: stopwatch.elapsed,
          );
        }
      }

      // Check if hit-testable (can receive taps)
      if (checkHitTestable) {
        final isHitTestable = _isElementHitTestable(tester, finder);
        if (!isHitTestable) {
          stopwatch.stop();
          return StepResult.failure(
            '$name is not hit-testable (obscured or pointer events disabled)',
            duration: stopwatch.elapsed,
          );
        }
      }

      stopwatch.stop();
      return StepResult.success(
        message: '$name is ready for interaction',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Element verification failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<bool> _waitForElement(
    WidgetTester tester,
    Finder finder,
    Duration timeout,
  ) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (tester.any(finder)) {
        return true;
      }
    }

    return false;
  }

  bool _isElementVisible(WidgetTester tester, Finder finder) {
    if (!tester.any(finder)) return false;

    try {
      final element = tester.element(finder);
      final renderObject = element.renderObject;

      if (renderObject == null || !renderObject.attached) {
        return false;
      }

      if (renderObject is RenderBox) {
        return renderObject.size.width > 0 && renderObject.size.height > 0;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isElementEnabled(WidgetTester tester, Finder finder) {
    if (!tester.any(finder)) return false;

    try {
      final widget = tester.widget(finder);

      // Check common widget types for enabled state
      if (widget is ElevatedButton ||
          widget is TextButton ||
          widget is OutlinedButton) {
        return (widget as dynamic).onPressed != null;
      }

      if (widget is TextField) {
        return widget.enabled ?? true;
      }

      // Default to true if we can't determine
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isElementHitTestable(WidgetTester tester, Finder finder) {
    if (!tester.any(finder)) return false;

    try {
      final element = tester.element(finder);
      final renderObject = element.renderObject;

      if (renderObject == null || !renderObject.attached) {
        return false;
      }

      if (renderObject is RenderBox) {
        final position = renderObject.localToGlobal(Offset.zero);
        final size = renderObject.size;

        // Simple hit test at center of widget
        final center = position + Offset(size.width / 2, size.height / 2);
        final result = HitTestResult();

        RendererBinding.instance.hitTest(result, center);

        // Check if our widget is in the hit test result
        return result.path.any((entry) => entry.target == renderObject);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Scroll element into view if needed
  Future<StepResult> scrollIntoView(
    WidgetTester tester,
    Finder finder, {
    String? elementName,
    double alignment = 0.5,
  }) async {
    final stopwatch = Stopwatch()..start();
    final name = elementName ?? 'Element';

    try {
      if (!tester.any(finder)) {
        stopwatch.stop();
        return StepResult.failure(
          '$name not found',
          duration: stopwatch.elapsed,
        );
      }

      // Try to scroll into view
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();

      stopwatch.stop();
      return StepResult.success(
        message: '$name scrolled into view',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed to scroll $name into view: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Get element information for debugging
  Map<String, dynamic> getElementInfo(WidgetTester tester, Finder finder) {
    final info = <String, dynamic>{
      'exists': tester.any(finder),
      'count': tester.widgetList(finder).length,
    };

    if (tester.any(finder)) {
      try {
        final widget = tester.widget(finder);
        info['type'] = widget.runtimeType.toString();
        info['visible'] = _isElementVisible(tester, finder);
        info['enabled'] = _isElementEnabled(tester, finder);
        info['hitTestable'] = _isElementHitTestable(tester, finder);

        final element = finder.evaluate().first;
        final renderObject = element.renderObject;
        if (renderObject != null && renderObject is RenderBox) {
          info['size'] = renderObject.size.toString();
          info['position'] = renderObject.localToGlobal(Offset.zero).toString();
        }
      } catch (e) {
        info['error'] = e.toString();
      }
    }

    return info;
  }

  /// Wait for element to disappear
  Future<StepResult> waitForElementToDisappear(
    WidgetTester tester,
    Finder finder, {
    String? elementName,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    final name = elementName ?? 'Element';
    final endTime = DateTime.now().add(timeout);

    try {
      while (DateTime.now().isBefore(endTime)) {
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        if (!tester.any(finder)) {
          stopwatch.stop();
          return StepResult.success(
            message: '$name disappeared',
            duration: stopwatch.elapsed,
          );
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      stopwatch.stop();
      return StepResult.failure(
        '$name still visible after ${timeout.inSeconds}s',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Error waiting for $name to disappear: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Verify multiple elements at once
  Future<Map<String, StepResult>> verifyMultipleElements(
    WidgetTester tester,
    Map<String, Finder> elements, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final results = <String, StepResult>{};

    for (final entry in elements.entries) {
      results[entry.key] = await verifyElement(
        tester,
        entry.value,
        elementName: entry.key,
        timeout: timeout,
      );
    }

    return results;
  }

  /// Check if element has specific text
  bool elementHasText(WidgetTester tester, Finder finder, String expectedText) {
    if (!tester.any(finder)) return false;

    try {
      final widget = tester.widget(finder);

      if (widget is Text) {
        return widget.data == expectedText;
      }

      if (widget is EditableText) {
        return widget.controller.text == expectedText;
      }

      if (widget is TextField) {
        return widget.controller?.text == expectedText;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get element's current text
  String? getElementText(WidgetTester tester, Finder finder) {
    if (!tester.any(finder)) return null;

    try {
      final widget = tester.widget(finder);

      if (widget is Text) {
        return widget.data;
      }

      if (widget is EditableText) {
        return widget.controller.text;
      }

      if (widget is TextField) {
        return widget.controller?.text;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Extension methods for easier element verification
extension ElementVerifierExtensions on WidgetTester {
  /// Verify element is ready for interaction
  Future<StepResult> verifyElement(
    Finder finder, {
    String? name,
    Duration? timeout,
  }) async {
    return await ElementVerifier.instance.verifyElement(
      this,
      finder,
      elementName: name,
      timeout: timeout ?? const Duration(seconds: 5),
    );
  }

  /// Scroll element into view
  Future<StepResult> scrollIntoView(Finder finder, {String? name}) async {
    return await ElementVerifier.instance.scrollIntoView(
      this,
      finder,
      elementName: name,
    );
  }

  /// Get element information
  Map<String, dynamic> getElementInfo(Finder finder) {
    return ElementVerifier.instance.getElementInfo(this, finder);
  }

  /// Wait for element to disappear
  Future<StepResult> waitForDisappear(
    Finder finder, {
    String? name,
    Duration? timeout,
  }) async {
    return await ElementVerifier.instance.waitForElementToDisappear(
      this,
      finder,
      elementName: name,
      timeout: timeout ?? const Duration(seconds: 5),
    );
  }
}
