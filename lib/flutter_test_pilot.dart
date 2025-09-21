// test_pilot.dart - Main entry point for Test Pilot
export 'package:flutter_test_pilot/src/test_pilot_runner.dart';
export 'package:flutter_test_pilot/src/nav/global_nav.dart';
export 'package:flutter_test_pilot/src/test_suite/step_result.dart';
export 'package:flutter_test_pilot/src/test_suite/test_action.dart';
export 'package:flutter_test_pilot/src/test_suite/test_result.dart';
export 'package:flutter_test_pilot/src/test_suite/test_status.dart';
export 'package:flutter_test_pilot/src/test_suite/test_suite.dart';
export 'package:flutter_test_pilot/src/test_suite/nav_action/navgator.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/tap/tap.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/type/type.dart';
export 'package:flutter_test_pilot/src/test_suite/wait_action/wait_action.dart';

export 'package:flutter_test_pilot/src/reporting/console_reporter.dart';
export 'package:flutter_test_pilot/src/reporting/json_reporter.dart';

export 'package:flutter_test_pilot/src/test_suite/apis/apis_checker.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/apis_observer_manager.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/apis_observer.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/request_resonse_check.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/checker/any_checker.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/checker/bool_checker.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/checker/custom_checker.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/checker/int_checker.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/checker/list_checker.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/checker/object_checker.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/checker/string_checker.dart';

export 'package:flutter_test_pilot/src/test_suite/apis/model/api_call_data.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/model/api_test_result.dart';
export 'package:flutter_test_pilot/src/test_suite/apis/model/api_validation_result.dart';

export 'package:flutter_test_pilot/src/test_suite/ui_interaction/advanced_gestures/drag.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/advanced_gestures/scroll.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/advanced_gestures/pinch.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/advanced_gestures/drop.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/advanced_gestures/swipe.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/advanced_gestures/pen.dart';

export 'package:flutter_test_pilot/src/test_suite/ui_interaction/form_interactions/checkbox.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/form_interactions/radio.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/form_interactions/slider.dart';
// export 'package:flutter_test_pilot/src/test_suite/ui_interaction/form_interactions/switch.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/form_interactions/dropdown.dart';
// export 'package:flutter_test_pilot/src/test_suite/ui_interaction/form_interactions/date_picker.dart
// export 'package:flutter_test_pilot/src/test_suite/ui_interaction/form_interactions/time_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/src/nav/global_nav.dart';
import 'package:flutter_test_pilot/src/reporting/json_reporter.dart';

import 'src/reporting/console_reporter.dart';
import 'src/test_suite/test_result.dart';
import 'src/test_suite/test_status.dart';
import 'src/test_suite/test_suite.dart';

/// Main Test Pilot class - Entry point for all testing functionality
class FlutterTestPilot {
  static FlutterTestPilot? _instance;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static WidgetTester? _currentTester;

  FlutterTestPilot._();

  /// Get singleton instance
  static FlutterTestPilot get instance {
    _instance ??= FlutterTestPilot._();
    return _instance!;
  }

  /// Initialize Test Pilot with navigator key
  static void initialize(WidgetTester tester) {
    _currentTester = tester;
    _navigatorKey = TestPilotNavigator.navigatorKey;
    debugPrint('🚀 Test Pilot initialized with navigator key');
  }

  /// Get current navigator key
  static GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Get current tester
  static WidgetTester? get currentTester => _currentTester;

  /// Run a single test suite
  Future<TestResult> runSuite(TestSuite suite) async {
    if (_currentTester == null) {
      throw Exception(
        'Test Pilot not properly initialized. Call setTester() first.',
      );
    }
    if (suite.steps.isEmpty) {
      throw ArgumentError('Test suite must have at least one test step');
    }

    debugPrint('🧪 Running test suite: ${suite.name}');
    final result = await suite.execute(_currentTester!);
    _printTestResult(result);
    return result;
  }

  /// Run multiple test suites as a group
  Future<List<TestResult>> runGroup(TestGroup group) async {
    if (_currentTester == null) {
      throw Exception(
        'Test Pilot not properly initialized. Call setTester() first.',
      );
    }

    debugPrint('📋 Running test group: ${group.name}');
    final results = <TestResult>[];

    for (final suite in group.suites) {
      try {
        final result = await suite.execute(_currentTester!);
        results.add(result);
        _printTestResult(result);

        // Stop on first failure if configured
        if (group.stopOnFailure && !result.status.isPassed) {
          debugPrint('⚠️ Stopping group execution due to failure');
          break;
        }
      } catch (e) {
        debugPrint('❌ Fatal error in suite ${suite.name}: $e');
        break;
      }
    }

    _printGroupSummary(group, results);
    return results;
  }

  /// Helper method to print individual test result
  void _printTestResult(TestResult result) async {
    ConsoleReporter().reportTest(result);
    JsonReporter().generateTestReport(result);
  }

  /// Helper method to print group summary
  void _printGroupSummary(TestGroup group, List<TestResult> results) async {
    ConsoleReporter().reportGroup(group, results);
    JsonReporter().generateGroupReport(group.name, results);
  }
}

// test_group.dart - For grouping multiple test suites
class TestGroup {
  final String name;
  final String? description;
  final List<TestSuite> suites;
  final bool stopOnFailure;
  final Duration? timeout;

  const TestGroup({
    required this.name,
    this.description,
    required this.suites,
    this.stopOnFailure = false,
    this.timeout,
  });
}

// test_status_extension.dart - Extension for TestStatus
extension TestStatusExtension on TestStatus {
  bool get isPassed => this == TestStatus.passed;
  bool get isFailed => this == TestStatus.failed;
  bool get isRunning => this == TestStatus.running;
  bool get isSkipped => this == TestStatus.skipped;
}
