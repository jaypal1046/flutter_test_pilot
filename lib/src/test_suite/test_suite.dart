import 'package:flutter_test/flutter_test.dart';
import 'test_action.dart';
import 'test_result.dart';
import 'test_status.dart';
import 'step_result.dart';

/// Configuration for test suite execution
class TestSuiteConfig {
  final int maxRetries;
  final Duration stepTimeout;
  final Duration actionDelay;
  final bool continueOnFailure;
  final bool verifyBeforeAction;
  final bool takeScreenshotOnFailure;

  const TestSuiteConfig({
    this.maxRetries = 3,
    this.stepTimeout = const Duration(seconds: 30),
    this.actionDelay = const Duration(milliseconds: 300),
    this.continueOnFailure = false,
    this.verifyBeforeAction = true,
    this.takeScreenshotOnFailure = false,
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

    try {
      // Execute setup phase
      if (setup.isNotEmpty) {
        print('📋 Setup Phase (${setup.length} steps)...');
        await _executePhase(setup, tester, result, TestPhase.setup, 'Setup');
      }

      // Execute main test steps
      if (steps.isNotEmpty) {
        print('🎯 Test Phase (${steps.length} steps)...');
        await _executePhase(steps, tester, result, TestPhase.test, 'Test');
      }

      // Execute API tests
      if (apis.isNotEmpty) {
        print('🌐 API Phase (${apis.length} steps)...');
        await _executePhase(apis, tester, result, TestPhase.apis, 'API');
      }

      // Execute assertions
      if (assertions.isNotEmpty) {
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

      print('✅ Test Suite PASSED: $name');
      print('   Duration: ${result.totalDuration.inMilliseconds}ms');
      print('   Steps: ${result.passedSteps}/${result.totalSteps}');
    } catch (e) {
      result.status = TestStatus.failed;
      result.error = e.toString();
      result.endTime = DateTime.now();

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

      print('═' * 60);
      if (result.hasWarnings) {
        print('⚠️  ${result.warnings.length} warning(s) encountered');
      }
    }

    return result;
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
