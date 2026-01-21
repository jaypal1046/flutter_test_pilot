library flutter_test_pilot;

// Re-export flutter_test for convenience (users only need to import flutter_test_pilot)
export 'package:flutter_test/flutter_test.dart' hide Timeout;

// Core test runner
export 'src/test_pilot_runner.dart';

// Test suite components
export 'src/test_suite/test_suite.dart';
export 'src/test_suite/test_action.dart';
export 'src/test_suite/test_result.dart';
export 'src/test_suite/test_status.dart';
export 'src/test_suite/step_result.dart';

// Discovery
export 'src/discovery/test_discovery.dart';

// Recording
export 'src/recording/test_recorder.dart';

// Navigation
export 'src/nav/global_nav.dart';

// Reporting
export 'src/reporting/ci_cd_reporter.dart';
export 'src/reporting/console_reporter.dart';
export 'src/reporting/json_reporter.dart';
export 'src/reporting/comprehensive_test_report_generator.dart'; // NEW: Auto report generation

// UI Interactions
export 'src/test_suite/ui_interaction/tap/tap.dart';
export 'src/test_suite/ui_interaction/type/type.dart';

// Wait actions
export 'src/test_suite/wait_action/wait_action.dart';
export 'src/test_suite/wait_action/smart_wait_actions.dart'; // NEW: Smart wait actions

// Navigation actions
export 'src/test_suite/nav_action/navigator.dart';

// Advanced gestures
export 'src/test_suite/ui_interaction/advanced_gestures/scroll.dart';

// Native action handler (Flutter-side permission dialog handler)
export 'src/test_suite/native_actions/native_action_handler.dart';

// NEW: Safe Pump Manager - Centralized pumping logic
export 'src/test_suite/pump/safe_pump_manager.dart';

// Utilities
export 'src/test_suite/utils/element_verifier.dart';

// Assertions
export 'src/test_suite/assertion_action/assertion_action.dart';

// 🌐 API Testing
export 'src/test_suite/apis/apis_observer.dart';
export 'src/test_suite/apis/apis_observer_manager.dart';
export 'src/test_suite/apis/apis_checker.dart';
export 'src/test_suite/apis/request_resonse_check.dart';

// API Models
export 'src/test_suite/apis/model/api_call_data.dart';
export 'src/test_suite/apis/model/api_validation_result.dart';
export 'src/test_suite/apis/model/api_test_result.dart';

// API Report Generator
export 'src/test_suite/apis/api_test_report_generator.dart';

// API Checkers - Type validation utilities
export 'src/test_suite/apis/checker/any_checker.dart';
export 'src/test_suite/apis/checker/bool_checker.dart';
export 'src/test_suite/apis/checker/custom_checker.dart';
export 'src/test_suite/apis/checker/int_checker.dart';
export 'src/test_suite/apis/checker/list_checker.dart';
export 'src/test_suite/apis/checker/object_checker.dart';
export 'src/test_suite/apis/checker/string_checker.dart';

// ✨ Test Generation
export 'src/generation/code_analyzer.dart';
export 'src/generation/test_generator.dart';
export 'src/generation/test_templates.dart';
export 'src/generation/auto_test_cli.dart'
    hide TestGenerationStrategy; // Hide to avoid conflict
export 'src/generation/flow_test_generator.dart'; // NEW: Flow-based generation

// 🔍 NEW: Custom Pilot Finder - Advanced widget finding system
export 'src/finder/pilot_finder.dart';
export 'src/finder/finder_strategies.dart';
export 'src/finder/finder_context.dart';
export 'src/finder/finder_cache.dart';

// Export enhanced tester extensions
export 'src/test_suite/extensions/enhanced_tester_extensions.dart';

// Export safe pump manager (already exported via extensions)
export 'src/test_suite/pump/safe_pump_manager.dart';

// Native Features (Phase 2 & 3)
export 'native/adb_commander.dart';
export 'native/permission_granter.dart';
export 'native/dialog_watcher.dart';
export 'native/native_handler.dart';
export 'native/watcher_config.dart'; // NEW: Export watcher configuration

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
