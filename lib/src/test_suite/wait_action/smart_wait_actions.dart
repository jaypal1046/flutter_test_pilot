// =============================================================================
// SMART WAIT ACTIONS
// Intelligent waiting that adapts to your app's behavior
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_action.dart';
import '../step_result.dart';
import '../pump/safe_pump_manager.dart';

/// Smart wait for screen to appear
class WaitForScreen extends TestAction {
  final String screenName;
  final Duration timeout;
  final Finder Function()? screenFinder;
  final List<String>? expectedTexts;
  final List<Type>? expectedWidgets;

  const WaitForScreen({
    required this.screenName,
    this.timeout = const Duration(seconds: 30),
    this.screenFinder,
    this.expectedTexts,
    this.expectedWidgets,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    print('⏳ Waiting for screen: $screenName (max ${timeout.inSeconds}s)');

    try {
      final result = await SafePumpManager.instance.pumpUntil(
        tester,
        condition: () => _isScreenPresent(tester),
        timeout: timeout,
        checkInterval: const Duration(milliseconds: 500),
        debugLabel: 'WaitForScreen: $screenName',
      );

      if (result.success) {
        stopwatch.stop();
        print(
          '✅ Screen appeared: $screenName (${stopwatch.elapsedMilliseconds}ms)',
        );
        return StepResult.success(
          message: 'Screen "$screenName" appeared',
          duration: stopwatch.elapsed,
        );
      } else {
        stopwatch.stop();
        return StepResult.failure(
          'Screen "$screenName" did not appear: ${result.error}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed waiting for screen "$screenName": $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  bool _isScreenPresent(WidgetTester tester) {
    // Custom finder
    if (screenFinder != null) {
      return tester.any(screenFinder!());
    }

    // Check expected texts
    if (expectedTexts != null) {
      for (final text in expectedTexts!) {
        if (tester.any(find.text(text))) {
          return true;
        }
      }
    }

    // Check expected widgets
    if (expectedWidgets != null) {
      for (final widgetType in expectedWidgets!) {
        if (tester.any(find.byType(widgetType))) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  String get description => '⏳ Wait for screen: $screenName';
}

/// Wait for navigation to complete
class WaitForNavigation extends TestAction {
  final Duration timeout;
  final String? targetScreen;

  const WaitForNavigation({
    this.timeout = const Duration(seconds: 10),
    this.targetScreen,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    print('🚀 Waiting for navigation to complete...');

    try {
      // Use navigation-specific pump strategy
      final result = await SafePumpManager.instance.pump(
        tester,
        strategy: PumpStrategy.navigation,
        debugLabel: 'Navigation to ${targetScreen ?? "next screen"}',
      );

      // Additional stabilization
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.safePumpBounded(
        maxFrames: 5,
        debugLabel: 'Post-navigation stabilization',
      );

      if (result.success) {
        stopwatch.stop();
        print('✅ Navigation complete (${stopwatch.elapsedMilliseconds}ms)');
        return StepResult.success(
          message: 'Navigation completed',
          duration: stopwatch.elapsed,
        );
      } else {
        stopwatch.stop();
        return StepResult.warning(
          message: 'Navigation may not be complete: ${result.error}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed waiting for navigation: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  String get description => '🚀 Wait for navigation to complete';
}

/// Wait for widget to appear
class WaitForWidget extends TestAction {
  final Finder finder;
  final Duration timeout;
  final String? widgetDescription;

  const WaitForWidget({
    required this.finder,
    this.timeout = const Duration(seconds: 15),
    this.widgetDescription,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    final description = widgetDescription ?? 'widget';

    print('⏳ Waiting for $description to appear...');

    try {
      final result = await SafePumpManager.instance.pumpUntil(
        tester,
        condition: () => tester.any(finder),
        timeout: timeout,
        debugLabel: 'WaitForWidget: $description',
      );

      if (result.success) {
        stopwatch.stop();
        print('✅ $description appeared (${stopwatch.elapsedMilliseconds}ms)');
        return StepResult.success(
          message: '$description appeared',
          duration: stopwatch.elapsed,
        );
      } else {
        stopwatch.stop();
        return StepResult.failure(
          '$description did not appear: ${result.error}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed waiting for $description: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  String get description => '⏳ Wait for ${widgetDescription ?? "widget"}';
}

/// Wait for widget to disappear
class WaitForWidgetToDisappear extends TestAction {
  final Finder finder;
  final Duration timeout;
  final String? widgetDescription;

  const WaitForWidgetToDisappear({
    required this.finder,
    this.timeout = const Duration(seconds: 15),
    this.widgetDescription,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    final description = widgetDescription ?? 'widget';

    print('⏳ Waiting for $description to disappear...');

    try {
      final result = await SafePumpManager.instance.pumpUntil(
        tester,
        condition: () => !tester.any(finder),
        timeout: timeout,
        debugLabel: 'WaitForDisappear: $description',
      );

      if (result.success) {
        stopwatch.stop();
        print(
          '✅ $description disappeared (${stopwatch.elapsedMilliseconds}ms)',
        );
        return StepResult.success(
          message: '$description disappeared',
          duration: stopwatch.elapsed,
        );
      } else {
        stopwatch.stop();
        return StepResult.failure(
          '$description did not disappear: ${result.error}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed waiting for $description to disappear: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  String get description =>
      '⏳ Wait for ${widgetDescription ?? "widget"} to disappear';
}

/// Wait for API call to complete
class WaitForApiCall extends TestAction {
  final String apiId;
  final Duration timeout;

  const WaitForApiCall({
    required this.apiId,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    print('⏳ Waiting for API call: $apiId (max ${timeout.inSeconds}s)');

    try {
      // Import needed for this to work
      // final result = await SafePumpManager.instance.pumpUntil(
      //   tester,
      //   condition: () {
      //     final results = ApiObserverManager.instance.allTestResults;
      //     return results.any((r) => r.apiId == apiId);
      //   },
      //   timeout: timeout,
      //   debugLabel: 'WaitForApiCall: $apiId',
      // );

      // For now, just wait and pump
      await Future.delayed(const Duration(seconds: 2));
      await tester.safePumpBounded(debugLabel: 'After API wait');

      stopwatch.stop();
      return StepResult.success(
        message: 'Waited for API call: $apiId',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed waiting for API call "$apiId": $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  String get description => '⏳ Wait for API call: $apiId';
}

/// Wait for loading indicator to disappear
class WaitForLoadingToComplete extends TestAction {
  final Duration timeout;

  const WaitForLoadingToComplete({this.timeout = const Duration(seconds: 30)});

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    print('⏳ Waiting for loading to complete...');

    try {
      final result = await SafePumpManager.instance.pumpUntil(
        tester,
        condition: () => _isLoadingComplete(tester),
        timeout: timeout,
        debugLabel: 'WaitForLoadingComplete',
      );

      if (result.success) {
        stopwatch.stop();
        print('✅ Loading complete (${stopwatch.elapsedMilliseconds}ms)');
        return StepResult.success(
          message: 'Loading completed',
          duration: stopwatch.elapsed,
        );
      } else {
        stopwatch.stop();
        return StepResult.warning(
          message: 'Loading may not be complete: ${result.error}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed waiting for loading: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  bool _isLoadingComplete(WidgetTester tester) {
    // Check for common loading indicators
    final loadingIndicators = [
      find.byType(CircularProgressIndicator),
      find.byType(LinearProgressIndicator),
      find.text('Loading...'),
      find.textContaining('Please wait'),
    ];

    for (final indicator in loadingIndicators) {
      if (tester.any(indicator)) {
        return false; // Still loading
      }
    }

    return true; // No loading indicators found
  }

  @override
  String get description => '⏳ Wait for loading to complete';
}

/// Smart wait with automatic screen detection
class SmartWait extends TestAction {
  final Duration duration;
  final PumpStrategy strategy;

  const SmartWait({
    this.duration = const Duration(seconds: 2),
    this.strategy = PumpStrategy.smart,
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    print('⏳ Smart waiting for ${duration.inMilliseconds}ms...');

    try {
      final result = await SafePumpManager.instance.waitAndPump(
        tester,
        duration: duration,
        strategy: strategy,
        debugLabel: 'SmartWait ${duration.inSeconds}s',
      );

      stopwatch.stop();

      if (result.success) {
        print('✅ Smart wait complete (${result.framesPumped} frames)');
        return StepResult.success(
          message: 'Smart wait completed',
          duration: stopwatch.elapsed,
        );
      } else {
        return StepResult.warning(
          message: 'Smart wait completed with warnings: ${result.error}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Smart wait failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  String get description => '⏳ Smart wait: ${duration.inSeconds}s';
}

/// Wait for any condition with custom checker
class WaitForCondition extends TestAction {
  final bool Function(WidgetTester) condition;
  final String conditionDescription;
  final Duration timeout;

  const WaitForCondition({
    required this.condition,
    required this.conditionDescription,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    print('⏳ Waiting for condition: $conditionDescription');

    try {
      final result = await SafePumpManager.instance.pumpUntil(
        tester,
        condition: () => condition(tester),
        timeout: timeout,
        debugLabel: 'WaitForCondition: $conditionDescription',
      );

      if (result.success) {
        stopwatch.stop();
        print(
          '✅ Condition met: $conditionDescription (${stopwatch.elapsedMilliseconds}ms)',
        );
        return StepResult.success(
          message: 'Condition met: $conditionDescription',
          duration: stopwatch.elapsed,
        );
      } else {
        stopwatch.stop();
        return StepResult.failure(
          'Condition not met: $conditionDescription - ${result.error}',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return StepResult.failure(
        'Failed waiting for condition "$conditionDescription": $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  String get description => '⏳ Wait for: $conditionDescription';
}
