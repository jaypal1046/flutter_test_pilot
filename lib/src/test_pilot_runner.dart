// test_pilot_runner.dart - Helper functions for running tests in test files
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_pilot.dart';
class TestPilotRunner {
  /// Helper to run a single suite within a testWidgets
  static Future<void> runSuite(
      WidgetTester tester,
      TestSuite suite, {
        bool expectSuccess = true,
      }) async {
    FlutterTestPilot.initialize(tester);

    final result = await FlutterTestPilot.instance.runSuite(suite);

    if (expectSuccess && !result.status.isPassed) {
      throw TestFailure('Test suite ${suite.name} failed: ${result.error}');
    }
  }

  /// Helper to run a group within a testWidgets
  static Future<void> runGroup(
      WidgetTester tester,
      TestGroup group, {
        bool expectAllSuccess = true,
      }) async {
    FlutterTestPilot.initialize(tester);

    final results = await FlutterTestPilot.instance.runGroup(group);

    if (expectAllSuccess) {
      final failures = results.where((r) => !r.status.isPassed).toList();
      if (failures.isNotEmpty) {
        final failureMessages = failures
            .map((r) => '${r.suiteName}: ${r.error}')
            .join(', ');
        throw TestFailure(
          'Test group ${group.name} had failures: $failureMessages',
        );
      }
    }
  }
}