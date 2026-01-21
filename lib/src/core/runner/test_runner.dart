import 'dart:io';
import 'dart:async';
import 'package:mason_logger/mason_logger.dart';

/// Result of a single test execution
class TestResult {
  final String testPath;
  final bool passed;
  final int durationMs;
  final String? errorMessage;
  final List<String> screenshots;

  TestResult({
    required this.testPath,
    required this.passed,
    required this.durationMs,
    this.errorMessage,
    this.screenshots = const [],
  });
}

/// Parallel test runner with smart scheduling
class TestRunner {
  final Logger logger;
  final int maxParallel;
  final bool verbose;

  TestRunner({
    required this.logger,
    this.maxParallel = 4,
    this.verbose = false,
  });

  /// Run multiple tests in parallel
  Future<List<TestResult>> runTests({
    required List<String> testPaths,
    required String deviceId,
    required String platform,
    int maxRetries = 2,
  }) async {
    final results = <TestResult>[];
    final tasks = <Future<TestResult>>[];

    logger.info('🚀 Running ${testPaths.length} tests in parallel (max: $maxParallel)');

    // Create a pool of test execution tasks
    for (final testPath in testPaths) {
      if (tasks.length >= maxParallel) {
        // Wait for at least one task to complete
        final completed = await Future.any(tasks);
        tasks.removeWhere((t) => t == Future.value(completed));
        results.add(completed);
      }

      // Add new task
      tasks.add(_runSingleTest(
        testPath: testPath,
        deviceId: deviceId,
        platform: platform,
        retries: maxRetries,
      ));
    }

    // Wait for remaining tasks
    final remaining = await Future.wait(tasks);
    results.addAll(remaining);

    return results;
  }

  /// Run a single test with retries
  Future<TestResult> _runSingleTest({
    required String testPath,
    required String deviceId,
    required String platform,
    int retries = 0,
  }) async {
    final startTime = DateTime.now();
    final progress = logger.progress('Running $testPath');

    try {
      final result = await _executeTest(testPath, deviceId, platform);
      final duration = DateTime.now().difference(startTime);

      if (result.exitCode == 0) {
        progress.complete('✅ $testPath passed (${duration.inSeconds}s)');
        return TestResult(
          testPath: testPath,
          passed: true,
          durationMs: duration.inMilliseconds,
        );
      } else {
        // Test failed
        if (retries > 0) {
          progress.update('🔄 Retrying $testPath ($retries attempts left)');
          await Future.delayed(Duration(seconds: 3));
          return await _runSingleTest(
            testPath: testPath,
            deviceId: deviceId,
            platform: platform,
            retries: retries - 1,
          );
        }

        progress.fail('❌ $testPath failed (${duration.inSeconds}s)');
        return TestResult(
          testPath: testPath,
          passed: false,
          durationMs: duration.inMilliseconds,
          errorMessage: result.stderr.toString(),
        );
      }
    } catch (e) {
      progress.fail('❌ $testPath error');
      return TestResult(
        testPath: testPath,
        passed: false,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        errorMessage: e.toString(),
      );
    }
  }

  Future<ProcessResult> _executeTest(
    String testPath,
    String deviceId,
    String platform,
  ) async {
    final args = [
      'test',
      testPath,
      '--device-id=$deviceId',
      if (verbose) '--verbose',
    ];

    return await Process.run('flutter', args);
  }

  /// Print summary of test results
  void printSummary(List<TestResult> results) {
    final passed = results.where((r) => r.passed).length;
    final failed = results.length - passed;
    final totalDuration = results.fold<int>(
      0,
      (sum, r) => sum + r.durationMs,
    );

    logger.info('\n' + '=' * 50);
    logger.info('📊 Test Summary');
    logger.info('=' * 50);
    logger.success('✅ Passed: $passed');
    if (failed > 0) {
      logger.err('❌ Failed: $failed');
    }
    logger.info('⏱️  Total Duration: ${(totalDuration / 1000).toStringAsFixed(1)}s');
    logger.info('⚡ Average: ${(totalDuration / results.length / 1000).toStringAsFixed(1)}s per test');

    if (failed > 0) {
      logger.info('\n❌ Failed Tests:');
      for (final result in results.where((r) => !r.passed)) {
        logger.err('   • ${result.testPath}');
      }
    }

    logger.info('=' * 50);
  }
}
