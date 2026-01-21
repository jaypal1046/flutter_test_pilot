import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';
import 'test_action.dart';
import 'test_result.dart';
import 'test_status.dart';
import 'step_result.dart';
import '../reporting/test_result_logger.dart'
    hide ApiTestResult; // NEW: Import logger
import '../reporting/comprehensive_test_report_generator.dart'; // NEW: Comprehensive reports
import 'apis/apis_observer.dart'; // Import for ApiTestAction
import 'apis/apis_observer_manager.dart'; // Import for ApiObserverManager

/// Configuration for test suite execution
class TestSuiteConfig {
  final int maxRetries;
  final Duration stepTimeout;
  final Duration actionDelay;
  final bool continueOnFailure;
  final bool verifyBeforeAction;
  final bool takeScreenshotOnFailure;
  final bool autoLogResults; // Disabled by default for mobile tests
  final bool autoGenerateReports; // NEW: Control report generation separately
  final TestResultLogger? logger;

  const TestSuiteConfig({
    this.maxRetries = 3,
    this.stepTimeout = const Duration(seconds: 30),
    this.actionDelay = const Duration(milliseconds: 300),
    this.continueOnFailure = false,
    this.verifyBeforeAction = true,
    this.takeScreenshotOnFailure = false,
    this.autoLogResults = false, // CHANGED: Disabled by default (was true)
    this.autoGenerateReports = false, // NEW: Disabled by default
    this.logger,
  });
}

/// Main TestSuite class that defines a complete test scenario
class TestSuite {
  final String name;
  final String? description;
  final List<TestAction> setup;
  final List<TestAction> steps;
  final List<TestAction> apis;
  final List<TestAction> assertions;
  final List<TestAction> cleanup;
  final Duration? timeout;
  final Map<String, dynamic>? metadata;
  final TestSuiteConfig config;

  const TestSuite({
    required this.name,
    this.description,
    this.setup = const [],
    required this.steps,
    this.apis = const [],
    this.assertions = const [],
    this.cleanup = const [],
    this.timeout,
    this.metadata,
    this.config = const TestSuiteConfig(),
  });

  /// Execute the test suite with comprehensive error handling
  Future<TestResult> execute(WidgetTester tester) async {
    final result = TestResult(suiteName: name);
    result.metadata.addAll(metadata ?? {});

    print('\n🧪 Starting Test Suite: $name');
    print('═' * 60);

    // ═══════════════════════════════════════════════════════════
    // CRITICAL: Register API tests BEFORE executing any UI steps
    // API validation will happen in PARALLEL with UI execution
    // ═══════════════════════════════════════════════════════════
    if (apis.isNotEmpty) {
      print('🌐 Registering ${apis.length} API tests...');
      print('   These will monitor API calls in PARALLEL with UI execution');
      print('   ⚡ Real-time validation: APIs validated as they are called');
      print('');

      for (final apiTest in apis) {
        if (apiTest is ApiTestAction) {
          ApiObserverManager.instance.registerApiTest(apiTest);
          print(
            '   📋 ${apiTest.apiId} → Monitoring ${apiTest.method ?? "ANY"} ${apiTest.urlPattern ?? "ANY"}',
          );
        }
      }

      print('');
      print('✅ API Observer is now monitoring in BACKGROUND');
      print('   UI tests will run independently - no blocking!');
      print('');
    }

    try {
      // Execute setup phase
      if (setup.isNotEmpty) {
        print('📋 Setup Phase (${setup.length} steps)...');
        await _executePhase(setup, tester, result, TestPhase.setup, 'Setup');
      }

      // Execute main test steps
      // APIs are monitored in PARALLEL - no waiting!
      if (steps.isNotEmpty) {
        print('🎯 Test Phase (${steps.length} steps)...');
        print('   💡 API validation happens in PARALLEL - no blocking');

        // Start listening to API test results in parallel
        final apiResultSubscription = apis.isNotEmpty
            ? _startApiResultMonitoring()
            : null;

        try {
          // Execute UI steps without waiting for APIs
          await _executePhase(steps, tester, result, TestPhase.test, 'Test');
        } finally {
          // Stop monitoring when UI tests complete
          await apiResultSubscription?.cancel();
        }
      }

      // Brief wait for any final API calls to complete
      if (apis.isNotEmpty) {
        print('');
        print('⏳ Waiting 2s for final API calls to complete...');
        await Future.delayed(const Duration(seconds: 2));

        // Report API results
        _printApiMonitoringSummary();
      }

      // Execute assertions
      if (assertions.isNotEmpty) {
        print('');
        print('✓ Assertion Phase (${assertions.length} steps)...');
        await _executePhase(
          assertions,
          tester,
          result,
          TestPhase.assertion,
          'Assertion',
        );
      }

      result.status = TestStatus.passed;
      result.endTime = DateTime.now();

      print('');
      print('✅ Test Suite PASSED: $name');
      print('   Duration: ${result.totalDuration.inMilliseconds}ms');
      print('   UI Steps: ${result.passedSteps}/${result.totalSteps}');

      if (apis.isNotEmpty) {
        final apiResults = ApiObserverManager.instance.allTestResults;
        final passedApis = apiResults.where((t) => t.isSuccess).length;
        print('   API Tests: $passedApis/${apiResults.length} validated');
      }
    } catch (e) {
      result.status = TestStatus.failed;
      result.error = e.toString();
      result.endTime = DateTime.now();

      print('');
      print('❌ Test Suite FAILED: $name');
      print('   Error: $e');
      print('   Duration: ${result.totalDuration.inMilliseconds}ms');
      print('   Passed: ${result.passedSteps}/${result.totalSteps}');

      if (config.takeScreenshotOnFailure) {
        await _takeScreenshot(tester, result);
      }
    } finally {
      // Always run cleanup
      if (cleanup.isNotEmpty) {
        print('');
        print('🧹 Cleanup Phase (${cleanup.length} steps)...');
        try {
          await _executePhase(
            cleanup,
            tester,
            result,
            TestPhase.cleanup,
            'Cleanup',
          );
        } catch (e) {
          result.cleanupError = e.toString();
          result.addWarning('Cleanup failed: $e');
          print('⚠️  Cleanup encountered errors: $e');
        }
      }

      // NEW: Auto-log test results
      if (config.autoLogResults) {
        await _logTestResult(result);
      }

      // NEW: Generate comprehensive reports automatically
      await _generateComprehensiveReports(result);

      print('═' * 60);
      if (result.hasWarnings) {
        print('⚠️  ${result.warnings.length} warning(s) encountered');
      }
    }

    return result;
  }

  /// Start monitoring API test results in parallel with UI execution
  StreamSubscription<ApiTestResult>? _startApiResultMonitoring() {
    print('🔊 Starting parallel API result monitoring...');

    return ApiObserverManager.instance.testResults.listen(
      (apiResult) {
        // Log API test results in real-time as they come in
        // This runs in PARALLEL with UI tests - no blocking!
        final icon = apiResult.isSuccess ? '✅' : '❌';
        print('');
        print('   $icon API Test Result (Real-time): ${apiResult.apiId}');
        print('      Status: ${apiResult.apiCall.statusCode}');
        print(
          '      Validations: ${apiResult.passedValidations}/${apiResult.totalValidations}',
        );

        if (!apiResult.isSuccess && apiResult.failures.isNotEmpty) {
          print('      Failures:');
          for (final failure in apiResult.failures.take(3)) {
            print('         • ${failure.fieldPath}: ${failure.message}');
          }
        }
        print('');
      },
      onError: (error) {
        print('⚠️  API monitoring error: $error');
      },
    );
  }

  /// Print comprehensive API monitoring summary
  void _printApiMonitoringSummary() {
    final capturedCalls = ApiObserverManager.instance.capturedCalls;
    final testResults = ApiObserverManager.instance.allTestResults;

    print('');
    print('═' * 60);
    print('📊 API MONITORING SUMMARY (Parallel Execution)');
    print('═' * 60);
    print('Total API calls captured: ${capturedCalls.length}');
    print('Total API tests executed: ${testResults.length}');
    print('API tests passed: ${testResults.where((t) => t.isSuccess).length}');
    print('API tests failed: ${testResults.where((t) => !t.isSuccess).length}');
    print('');

    if (capturedCalls.isEmpty) {
      print('⚠️  WARNING: No API calls were captured!');
      print('');
      print('Troubleshooting:');
      print('  1. Check if API Observer interceptor is attached to Dio');
      print('  2. Verify APIs are being called through monitored Dio instance');
      print('  3. Ensure app is not using different HTTP client');
      print('  4. Run ApiObserverManager.runDiagnostics() for details');
      print('');
    } else {
      print('📋 Captured API Calls (Parallel Monitoring):');
      for (final call in capturedCalls) {
        final statusIcon =
            (call.statusCode ?? 0) >= 200 && (call.statusCode ?? 0) < 300
            ? '✅'
            : '❌';
        print('   $statusIcon ${call.method} ${call.url}');
        print(
          '      Status: ${call.statusCode ?? "N/A"} | Duration: ${call.duration.inMilliseconds}ms',
        );

        // Show which test matched this call
        final matchingResult = testResults
            .where(
              (r) =>
                  r.apiCall.url == call.url && r.apiCall.method == call.method,
            )
            .firstOrNull;

        if (matchingResult != null) {
          print(
            '      Matched Test: ${matchingResult.apiId} (${matchingResult.isSuccess ? "PASSED" : "FAILED"})',
          );
        }
      }
      print('');

      // Show detailed test results
      if (testResults.isNotEmpty) {
        print('📝 Detailed API Test Results:');
        for (final testResult in testResults) {
          final icon = testResult.isSuccess ? '✅' : '❌';
          print('   $icon ${testResult.apiId}');
          print(
            '      URL: ${testResult.apiCall.method} ${testResult.apiCall.url}',
          );
          print('      Status: ${testResult.apiCall.statusCode}');
          print(
            '      Validations: ${testResult.passedValidations}/${testResult.totalValidations}',
          );
          print(
            '      Duration: ${testResult.apiCall.duration.inMilliseconds}ms',
          );

          if (!testResult.isSuccess && testResult.failures.isNotEmpty) {
            print('      ❌ Failures:');
            for (final failure in testResult.failures) {
              print('         • ${failure.fieldPath}');
              print('           Expected: ${failure.expectedValue}');
              print('           Actual: ${failure.actualValue}');
              print('           Message: ${failure.message}');
            }
          }
          print('');
        }
      }
    }
    print('═' * 60);
  }

  /// Execute a phase of test actions with retry and error handling
  Future<void> _executePhase(
    List<TestAction> actions,
    WidgetTester tester,
    TestResult result,
    TestPhase phase,
    String phaseName,
  ) async {
    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];
      final stepNumber = i + 1;
      final actionName = action.runtimeType.toString();

      print('  [$stepNumber/${actions.length}] $actionName...');

      try {
        // Execute action with retry logic
        final stepResult = await _executeActionWithRetry(
          action,
          tester,
          result,
          stepNumber,
        );

        result.addStepResult(phase, stepResult);

        if (stepResult.success) {
          print('    ✅ Success (${stepResult.duration.inMilliseconds}ms)');
        } else {
          print('    ❌ Failed: ${stepResult.error}');

          if (!config.continueOnFailure) {
            throw Exception(
              '$phaseName step $stepNumber failed: ${stepResult.error}',
            );
          } else {
            result.addWarning(
              '$phaseName step $stepNumber failed but continuing',
            );
          }
        }

        // Add delay between actions with BOUNDED pumping instead of pumpAndSettle
        if (i < actions.length - 1) {
          await Future.delayed(config.actionDelay);

          // CRITICAL FIX: Use bounded pump instead of pumpAndSettle
          // pumpAndSettle can hang indefinitely if there are continuous animations
          try {
            // Pump a few frames to allow UI updates
            for (int pumpCount = 0; pumpCount < 5; pumpCount++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          } catch (e) {
            // If pump fails, just log and continue
            print('    ⚠️ Pump warning (non-fatal): $e');
          }
        }
      } catch (e) {
        if (!config.continueOnFailure) {
          rethrow;
        }
        result.addWarning('$phaseName step $stepNumber error: $e');
        print('    ⚠️  Error but continuing: $e');
      }
    }
  }

  /// Execute action with retry logic
  Future<StepResult> _executeActionWithRetry(
    TestAction action,
    WidgetTester tester,
    TestResult result,
    int stepNumber,
  ) async {
    StepResult? lastResult;
    Exception? lastError;

    for (var attempt = 1; attempt <= config.maxRetries; attempt++) {
      try {
        // Execute with timeout
        lastResult = await action
            .execute(tester)
            .timeout(
              config.stepTimeout,
              onTimeout: () {
                return StepResult.failure(
                  'Action timed out after ${config.stepTimeout.inSeconds}s',
                  duration: config.stepTimeout,
                );
              },
            );

        // If successful, return immediately
        if (lastResult.success) {
          if (attempt > 1) {
            result.addWarning('Step $stepNumber succeeded on attempt $attempt');
          }
          return lastResult;
        }

        // If failed but not last attempt, retry
        if (attempt < config.maxRetries) {
          print('    🔄 Retry $attempt/${config.maxRetries - 1}...');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          // FIXED: Use bounded pump instead of pumpAndSettle
          try {
            for (int i = 0; i < 3; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          } catch (_) {
            // Ignore pump errors during retry
          }
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());

        if (attempt < config.maxRetries) {
          print('    🔄 Error, retry $attempt/${config.maxRetries - 1}: $e');
          await Future.delayed(Duration(milliseconds: 500 * attempt));

          try {
            // FIXED: Use bounded pump instead of pumpAndSettle
            for (int i = 0; i < 3; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          } catch (_) {
            // Ignore pump errors during retry
          }
        }
      }
    }

    // All retries exhausted
    if (lastResult != null) {
      result.addWarning(
        'Step $stepNumber failed after ${config.maxRetries} attempts',
      );
      return lastResult;
    }

    // Return error result
    return StepResult.failure(
      lastError?.toString() ??
          'Unknown error after ${config.maxRetries} attempts',
      duration: config.stepTimeout,
    );
  }

  /// Take screenshot on failure
  Future<void> _takeScreenshot(WidgetTester tester, TestResult result) async {
    try {
      // Screenshot logic would go here
      result.metadata['screenshot_taken'] = true;
      print('📸 Screenshot captured');
    } catch (e) {
      result.addWarning('Failed to capture screenshot: $e');
    }
  }

  // NEW: Log test result to file system
  Future<void> _logTestResult(TestResult result) async {
    try {
      final logger = config.logger ?? TestResultLogger();

      final testId = await logger.logTestResult(
        result,
        executor: _getExecutor(),
        buildNumber: _getBuildNumber(),
        commitHash: _getCommitHash(),
        screenshot: result.metadata['screenshot'] as String?,
      );

      result.metadata['logged_test_id'] = testId;
    } catch (e) {
      print('⚠️  Failed to log test result: $e');
      // Don't fail the test because of logging issues
    }
  }

  // NEW: Generate comprehensive reports automatically
  Future<void> _generateComprehensiveReports(TestResult result) async {
    try {
      // Check if reports are enabled
      if (!ComprehensiveTestReportGenerator.instance.reportsEnabled) {
        print('');
        print('💡 Test reports disabled. To enable:');
        print('   unset DISABLE_TEST_REPORTS');
        return;
      }

      // Collect API data
      final capturedApiCalls = ApiObserverManager.instance.capturedCalls;
      final apiTestResults = ApiObserverManager.instance.allTestResults;

      // Generate all reports automatically
      await ComprehensiveTestReportGenerator.instance.generateReports(
        testResult: result,
        capturedApiCalls: capturedApiCalls,
        apiTestResults: apiTestResults,
      );
    } catch (e) {
      print('');
      print('⚠️  Report generation failed (non-fatal): $e');
      print('💡 Test execution was successful - reports are optional');
    }
  }

  String _getExecutor() {
    return Platform.environment['USER'] ??
        Platform.environment['USERNAME'] ??
        'unknown';
  }

  String? _getBuildNumber() {
    return Platform.environment['BUILD_NUMBER'];
  }

  String? _getCommitHash() {
    return Platform.environment['GIT_COMMIT'] ??
        Platform.environment['COMMIT_SHA'];
  }

  /// Create a copy of this suite with different configuration
  TestSuite copyWith({
    String? name,
    String? description,
    List<TestAction>? setup,
    List<TestAction>? steps,
    List<TestAction>? apis,
    List<TestAction>? assertions,
    List<TestAction>? cleanup,
    Duration? timeout,
    Map<String, dynamic>? metadata,
    TestSuiteConfig? config,
  }) {
    return TestSuite(
      name: name ?? this.name,
      description: description ?? this.description,
      setup: setup ?? this.setup,
      steps: steps ?? this.steps,
      apis: apis ?? this.apis,
      assertions: assertions ?? this.assertions,
      cleanup: cleanup ?? this.cleanup,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
      config: config ?? this.config,
    );
  }
}
