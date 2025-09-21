import 'package:flutter_test/flutter_test.dart';
import 'test_action.dart';
import 'test_result.dart';
import 'test_status.dart';

/// Main TestSuite class that defines a complete test scenario
class TestSuite {
  final String name;
  final String? description;
  final List<TestAction> setup;
  final List<TestAction> steps;
  final List<TestAction> apis;
  final List<TestAction> cleanup;
  final Duration? timeout;
  final Map<String, dynamic>? metadata;

  const TestSuite({
    required this.name,
    this.description,
    this.setup = const [],
    required this.steps,
    this.apis = const [],
    this.cleanup = const [],
    this.timeout,
    this.metadata,
  });

  /// Execute the test suite
  Future<TestResult> execute(WidgetTester tester) async {
    final result = TestResult(suiteName: name);

    try {
      // Execute setup steps
      for (final action in setup) {
        await _executeAction(action, tester, result, TestPhase.setup);
      }

      // Execute main test steps
      for (final action in steps) {
        await _executeAction(action, tester, result, TestPhase.test);
      }

      for (final action in apis) {
        await _executeAction(action, tester, result, TestPhase.apis);
      }

      result.status = TestStatus.passed;
    } catch (e) {
      result.status = TestStatus.failed;
      result.error = e.toString();
    } finally {
      // Always run cleanup
      try {
        for (final action in cleanup) {
          await _executeAction(action, tester, result, TestPhase.cleanup);
        }
      } catch (e) {
        result.cleanupError = e.toString();
      }
    }

    return result;
  }

  Future<void> _executeAction(
    TestAction action,
    WidgetTester tester,
    TestResult result,
    TestPhase phase,
  ) async {
    final stepResult = await action.execute(tester);
    result.addStepResult(phase, stepResult);

    if (!stepResult.success) {
      throw Exception('${action.runtimeType} failed: ${stepResult.error}');
    }
  }
}
