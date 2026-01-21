import 'dart:async';
import 'dart:collection';
import '../core/models/test_result.dart';

/// Executes tests in parallel across multiple devices
class ParallelExecutor {
  final int maxConcurrency;
  final bool loadBalance;

  ParallelExecutor({this.maxConcurrency = 3, this.loadBalance = true});

  /// Run multiple tests in parallel across available devices
  Future<List<TestResult>> runParallel({
    required List<String> testFiles,
    required List<String> deviceIds,
    required Future<TestResult> Function(String testFile, String deviceId)
    testRunner,
    void Function(String testFile, String deviceId, String status)? onProgress,
  }) async {
    if (testFiles.isEmpty) {
      return [];
    }

    if (deviceIds.isEmpty) {
      throw Exception('No devices available for parallel execution');
    }

    print(
      '🚀 Running ${testFiles.length} tests on ${deviceIds.length} device(s) in parallel',
    );
    print('   Max concurrency: $maxConcurrency\n');

    // Create work queue
    final queue = Queue<String>.from(testFiles);
    final results = <TestResult>[];
    final activeTasks = <Future<void>>[];
    final deviceStats = <String, DeviceStats>{};

    // Initialize device stats
    for (final deviceId in deviceIds) {
      deviceStats[deviceId] = DeviceStats(deviceId: deviceId);
    }

    // Create workers for each device
    final workers = deviceIds.take(maxConcurrency).map((deviceId) {
      return _runWorker(
        deviceId: deviceId,
        queue: queue,
        results: results,
        deviceStats: deviceStats,
        testRunner: testRunner,
        onProgress: onProgress,
      );
    }).toList();

    // Wait for all workers to complete
    await Future.wait(workers);

    // Print summary
    _printSummary(results, deviceStats);

    return results;
  }

  /// Worker that processes tests from queue
  Future<void> _runWorker({
    required String deviceId,
    required Queue<String> queue,
    required List<TestResult> results,
    required Map<String, DeviceStats> deviceStats,
    required Future<TestResult> Function(String testFile, String deviceId)
    testRunner,
    void Function(String testFile, String deviceId, String status)? onProgress,
  }) async {
    final stats = deviceStats[deviceId]!;

    while (queue.isNotEmpty) {
      final testFile = queue.removeFirst();

      print('[Device $deviceId] 🧪 Running: $testFile');
      onProgress?.call(testFile, deviceId, 'running');
      stats.testsStarted++;

      final startTime = DateTime.now();

      try {
        final result = await testRunner(testFile, deviceId);
        final duration = DateTime.now().difference(startTime);

        results.add(result);
        stats.totalDuration += duration;

        if (result.passed) {
          print(
            '[Device $deviceId] ✅ Passed: $testFile (${duration.inSeconds}s)',
          );
          stats.testsPassed++;
          onProgress?.call(testFile, deviceId, 'passed');
        } else {
          print(
            '[Device $deviceId] ❌ Failed: $testFile (${duration.inSeconds}s)',
          );
          stats.testsFailed++;
          onProgress?.call(testFile, deviceId, 'failed');
        }
      } catch (e) {
        print('[Device $deviceId] ❌ Error: $testFile - $e');
        stats.testsFailed++;
        onProgress?.call(testFile, deviceId, 'error');

        results.add(
          TestResult(
            testPath: testFile,
            testHash: '',
            passed: false,
            duration: DateTime.now().difference(startTime),
            timestamp: DateTime.now(),
            deviceId: deviceId,
            errorMessage: e.toString(),
          ),
        );
      }
    }

    print('[Device $deviceId] 🏁 Worker finished');
  }

  /// Run tests with load balancing
  Future<List<TestResult>> runWithLoadBalancing({
    required List<String> testFiles,
    required List<String> deviceIds,
    required Future<TestResult> Function(String testFile, String deviceId)
    testRunner,
    Map<String, Duration>? estimatedDurations,
  }) async {
    if (!loadBalance || estimatedDurations == null) {
      return await runParallel(
        testFiles: testFiles,
        deviceIds: deviceIds,
        testRunner: testRunner,
      );
    }

    // Sort tests by estimated duration (longest first)
    final sortedTests = List<String>.from(testFiles)
      ..sort((a, b) {
        final durationA = estimatedDurations[a] ?? Duration.zero;
        final durationB = estimatedDurations[b] ?? Duration.zero;
        return durationB.compareTo(durationA);
      });

    print('📊 Load balancing enabled (running longest tests first)');

    return await runParallel(
      testFiles: sortedTests,
      deviceIds: deviceIds,
      testRunner: testRunner,
    );
  }

  /// Run tests in batches
  Future<List<TestResult>> runInBatches({
    required List<String> testFiles,
    required List<String> deviceIds,
    required Future<TestResult> Function(String testFile, String deviceId)
    testRunner,
    int batchSize = 10,
  }) async {
    final allResults = <TestResult>[];
    final batches = _createBatches(testFiles, batchSize);

    print(
      '🔢 Running ${testFiles.length} tests in ${batches.length} batch(es)',
    );

    for (var i = 0; i < batches.length; i++) {
      final batch = batches[i];
      print('\n📦 Batch ${i + 1}/${batches.length} (${batch.length} tests)');

      final batchResults = await runParallel(
        testFiles: batch,
        deviceIds: deviceIds,
        testRunner: testRunner,
      );

      allResults.addAll(batchResults);

      // Small delay between batches to avoid overwhelming devices
      if (i < batches.length - 1) {
        await Future.delayed(Duration(seconds: 2));
      }
    }

    return allResults;
  }

  List<List<String>> _createBatches(List<String> items, int batchSize) {
    final batches = <List<String>>[];
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  void _printSummary(
    List<TestResult> results,
    Map<String, DeviceStats> deviceStats,
  ) {
    print('\n📊 Parallel Execution Summary:');
    print('   Total tests: ${results.length}');
    print('   Passed: ${results.where((r) => r.passed).length}');
    print('   Failed: ${results.where((r) => !r.passed).length}');

    final totalDuration = results.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.duration,
    );
    final maxDuration = results.isEmpty
        ? Duration.zero
        : results.map((r) => r.duration).reduce((a, b) => a > b ? a : b);

    print('   Total time: ${totalDuration.inSeconds}s');
    print('   Wall clock time: ${maxDuration.inSeconds}s');

    if (totalDuration.inSeconds > 0 && maxDuration.inSeconds > 0) {
      final speedup = totalDuration.inSeconds / maxDuration.inSeconds;
      print('   Speedup: ${speedup.toStringAsFixed(1)}x');
    }

    print('\n📱 Device Statistics:');
    for (final stats in deviceStats.values) {
      if (stats.testsStarted > 0) {
        print('   ${stats.deviceId}:');
        print('     Tests: ${stats.testsPassed}/${stats.testsStarted} passed');
        print('     Duration: ${stats.totalDuration.inSeconds}s');
      }
    }
  }

  /// Calculate optimal device count
  static int calculateOptimalDeviceCount(int testCount, int avgTestDuration) {
    if (testCount <= 3) return 1;
    if (testCount <= 10) return 2;
    if (testCount <= 20) return 3;
    return 4;
  }
}

/// Statistics per device
class DeviceStats {
  final String deviceId;
  int testsStarted = 0;
  int testsPassed = 0;
  int testsFailed = 0;
  Duration totalDuration = Duration.zero;

  DeviceStats({required this.deviceId});

  double get successRate => testsStarted > 0 ? testsPassed / testsStarted : 0.0;

  @override
  String toString() {
    return 'DeviceStats($deviceId: $testsPassed/$testsStarted passed, '
        '${totalDuration.inSeconds}s)';
  }
}
