import 'dart:io';
import '../core/models/test_result.dart';

/// Handles test retries with exponential backoff
class RetryHandler {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  RetryHandler({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 5),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 2),
  });

  /// Run a test with automatic retry on failure
  Future<TestResult> runWithRetry({
    required String testPath,
    required String deviceId,
    required Future<TestResult> Function() testRunner,
    void Function(int attempt, int maxAttempts, Duration delay)? onRetry,
    bool Function(TestResult result)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;
    TestResult? lastResult;

    while (attempt <= maxRetries) {
      attempt++;

      print('🧪 Attempt $attempt/${maxRetries + 1}: Running test...');

      try {
        final result = await testRunner();
        lastResult = result;

        if (result.passed) {
          if (attempt > 1) {
            print('✅ Test passed on attempt $attempt');
          }
          return result;
        }

        // Check if we should retry
        final shouldRetryTest = shouldRetry?.call(result) ?? true;

        if (!shouldRetryTest || attempt > maxRetries) {
          print('❌ Test failed after $attempt attempt(s)');
          return result;
        }

        // Wait before retry with exponential backoff
        print('⏳ Waiting ${currentDelay.inSeconds}s before retry...');
        onRetry?.call(attempt, maxRetries, currentDelay);

        await Future.delayed(currentDelay);

        // Increase delay for next retry (exponential backoff)
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier)
              .round(),
        );

        // Cap at max delay
        if (currentDelay > maxDelay) {
          currentDelay = maxDelay;
        }
      } catch (e, stackTrace) {
        print('❌ Error on attempt $attempt: $e');

        if (attempt > maxRetries) {
          return TestResult(
            testPath: testPath,
            testHash: '',
            passed: false,
            duration: Duration.zero,
            timestamp: DateTime.now(),
            deviceId: deviceId,
            errorMessage: 'Failed after $attempt attempts: $e',
          );
        }

        print('⏳ Waiting ${currentDelay.inSeconds}s before retry...');
        await Future.delayed(currentDelay);

        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier)
              .round(),
        );
        if (currentDelay > maxDelay) {
          currentDelay = maxDelay;
        }
      }
    }

    // Should not reach here, but just in case
    return lastResult ??
        TestResult(
          testPath: testPath,
          testHash: '',
          passed: false,
          duration: Duration.zero,
          timestamp: DateTime.now(),
          deviceId: deviceId,
          errorMessage: 'Unknown retry failure',
        );
  }

  /// Retry a specific test result
  Future<TestResult> retryTest({
    required TestResult failedResult,
    required Future<TestResult> Function() testRunner,
  }) async {
    return await runWithRetry(
      testPath: failedResult.testPath,
      deviceId: failedResult.deviceId ?? 'unknown',
      testRunner: testRunner,
    );
  }

  /// Batch retry multiple failed tests
  Future<List<TestResult>> retryMultiple({
    required List<TestResult> failedResults,
    required Future<TestResult> Function(TestResult) testRunner,
    bool parallel = false,
  }) async {
    if (parallel) {
      final futures = failedResults.map((result) {
        return retryTest(
          failedResult: result,
          testRunner: () => testRunner(result),
        );
      });
      return await Future.wait(futures);
    } else {
      final results = <TestResult>[];
      for (final result in failedResults) {
        final retryResult = await retryTest(
          failedResult: result,
          testRunner: () => testRunner(result),
        );
        results.add(retryResult);
      }
      return results;
    }
  }

  /// Calculate next retry delay
  Duration calculateDelay(int attempt) {
    var delay = Duration(
      milliseconds:
          (initialDelay.inMilliseconds * (backoffMultiplier * attempt)).round(),
    );

    if (delay > maxDelay) {
      delay = maxDelay;
    }

    return delay;
  }

  /// Check if error is retriable
  static bool isRetriableError(String? errorMessage) {
    if (errorMessage == null) return true;

    final retriablePatterns = [
      'timeout',
      'network',
      'connection',
      'unavailable',
      'not responding',
      'flaky',
      'intermittent',
    ];

    final errorLower = errorMessage.toLowerCase();
    return retriablePatterns.any((pattern) => errorLower.contains(pattern));
  }

  /// Get retry statistics
  RetryStats getStats(List<TestResult> results) {
    final totalTests = results.length;
    final passedFirstTry = results.where((r) => r.passed).length;
    final failed = results.where((r) => !r.passed).length;

    return RetryStats(
      totalTests: totalTests,
      passedFirstTry: passedFirstTry,
      failed: failed,
      retrySuccessRate: totalTests > 0 ? passedFirstTry / totalTests : 0.0,
    );
  }
}

/// Retry statistics
class RetryStats {
  final int totalTests;
  final int passedFirstTry;
  final int failed;
  final double retrySuccessRate;

  RetryStats({
    required this.totalTests,
    required this.passedFirstTry,
    required this.failed,
    required this.retrySuccessRate,
  });

  @override
  String toString() {
    return 'RetryStats(total: $totalTests, passed: $passedFirstTry, '
        'failed: $failed, success rate: ${(retrySuccessRate * 100).toStringAsFixed(1)}%)';
  }
}
