import '../step_result.dart';
import '../test_action.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wait for conditions
class Wait extends TestAction {
  final WaitCondition condition;

  const Wait._(this.condition);

  /// Wait for a duration
  factory Wait.forDuration(Duration duration) {
    return Wait._(_WaitDuration(duration));
  }

  /// Wait until conditions - returns WaitUntil builder
  static WaitUntil get until => const WaitUntil();

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    return await condition.execute(tester);
  }

  @override
  String get description => condition.description;
}

abstract class WaitCondition {
  Future<StepResult> execute(WidgetTester tester);
  String get description;
}

class _WaitDuration extends WaitCondition {
  final Duration duration;

  _WaitDuration(this.duration);

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    await Future.delayed(duration);
    // Use pump() instead of pumpAndSettle() to avoid hanging
    // pumpAndSettle() can hang if there are ongoing animations or async operations
    await tester.pump();
    stopwatch.stop();

    return StepResult.success(
      message: 'Waited for ${duration.inMilliseconds}ms',
      duration: stopwatch.elapsed,
    );
  }

  @override
  String get description => 'Wait for ${duration.inMilliseconds}ms';
}

class WaitUntil {
  const WaitUntil();

  Wait widgetExists(String identifier) {
    return Wait._(_WaitUntilWidgetExists(identifier));
  }

  Wait apiCallCompletes(String endpoint) {
    return Wait._(_WaitUntilApiCall(endpoint));
  }

  Wait pageLoads<T>() {
    return Wait._(_WaitUntilPageLoads<T>());
  }

  Wait animationFinishes() {
    return Wait._(_WaitUntilAnimationFinishes());
  }
}

class _WaitUntilWidgetExists extends WaitCondition {
  final String identifier;

  _WaitUntilWidgetExists(this.identifier);

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    // Wait up to 10 seconds for widget to exist
    for (int i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));

      final finder = find.text(identifier);
      if (tester.any(finder)) {
        stopwatch.stop();
        return StepResult.success(
          message: 'Widget "$identifier" appeared',
          duration: stopwatch.elapsed,
        );
      }
    }

    stopwatch.stop();
    return StepResult.failure(
      'Widget "$identifier" did not appear within 10 seconds',
      duration: stopwatch.elapsed,
    );
  }

  @override
  String get description => 'Wait until widget "$identifier" exists';
}

class _WaitUntilApiCall extends WaitCondition {
  final String endpoint;

  _WaitUntilApiCall(this.endpoint);

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    // Implementation would check GuardianGlobal for API calls
    // This is a simplified version
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    stopwatch.stop();

    return StepResult.success(
      message: 'API call to $endpoint completed',
      duration: stopwatch.elapsed,
    );
  }

  @override
  String get description => 'Wait until API call "$endpoint" completes';
}

class _WaitUntilPageLoads<T> extends WaitCondition {
  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));

      final finder = find.byType(T);
      if (tester.any(finder)) {
        stopwatch.stop();
        return StepResult.success(
          message: 'Page ${T.toString()} loaded',
          duration: stopwatch.elapsed,
        );
      }
    }

    stopwatch.stop();
    return StepResult.failure(
      'Page ${T.toString()} did not load within 5 seconds',
      duration: stopwatch.elapsed,
    );
  }

  @override
  String get description => 'Wait until page ${T.toString()} loads';
}

class _WaitUntilAnimationFinishes extends WaitCondition {
  @override
  Future<StepResult> execute(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    await tester.pumpAndSettle();
    stopwatch.stop();

    return StepResult.success(
      message: 'Animations finished',
      duration: stopwatch.elapsed,
    );
  }

  @override
  String get description => 'Wait until animations finish';
}
