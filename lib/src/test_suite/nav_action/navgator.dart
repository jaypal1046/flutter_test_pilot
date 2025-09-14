// =============================================================================
// NAVIGATION ACTIONS
// =============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../nav/global_nav.dart';
import '../step_result.dart';
import '../test_action.dart';

/// Navigate to a route
class Navigate extends TestAction {
  final String? route;
  final Type? pageType;
  final Object? arguments;
  final bool replace;

  const Navigate._({this.route, this.pageType, this.arguments, this.replace = false});

  /// Navigate to a named route
  factory Navigate.to(String route, {Object? arguments}) {
    return Navigate._(route: route, arguments: arguments);
  }

  /// Navigate to a specific page type
  factory Navigate.toPage({Object? arguments}) {
  return Navigate._(pageType: Widget, arguments: arguments);
  }

  /// Replace current route
  factory Navigate.replace(String route, {Object? arguments}) {
    return Navigate._(route: route, arguments: arguments, replace: true);
  }

  /// Go back
  factory Navigate.back() {
    return const _NavigateBack();
  }

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (route != null) {
        if (replace) {
          await TestPilotNavigator.pushAndReplace(route!, arguments: arguments);
        } else {
          await TestPilotNavigator.pushTo(route!, arguments: arguments);
        }
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      return StepResult.success(
        message: 'Navigated to ${route ?? pageType}',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure('Navigation failed: $e', duration: stopwatch.elapsed);
    }
  }

  @override
  String get description => 'Navigate to ${route ?? pageType}';
}

class _NavigateBack extends Navigate {
  const _NavigateBack() : super._();

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    try {
      TestPilotNavigator.pop();
      await tester.pumpAndSettle();
      stopwatch.stop();

      return StepResult.success(
        message: 'Navigated back',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure('Navigate back failed: $e', duration: stopwatch.elapsed);
    }
  }

  @override
  String get description => 'Navigate back';
}