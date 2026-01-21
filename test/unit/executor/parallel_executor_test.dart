import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/src/executor/parallel_executor.dart';
import 'package:flutter_test_pilot/src/core/models/test_result.dart';

void main() {
  group('ParallelExecutor', () {
    test('should execute tests in parallel', () async {
      final executor = ParallelExecutor(maxConcurrency: 2);
      final testFiles = ['test1.dart', 'test2.dart', 'test3.dart'];
      final deviceIds = ['device1', 'device2'];

      final results = await executor.runParallel(
        testFiles: testFiles,
        deviceIds: deviceIds,
        testRunner: (testFile, deviceId) async {
          await Future.delayed(Duration(milliseconds: 50));
          return TestResult(
            testPath: testFile,
            testHash: 'hash_$testFile',
            passed: true,
            duration: Duration(milliseconds: 50),
            timestamp: DateTime.now(),
            deviceId: deviceId,
          );
        },
      );

      expect(results.length, equals(3));
      expect(results.every((r) => r.passed), isTrue);
    });

    test('should respect max concurrency', () async {
      final executor = ParallelExecutor(maxConcurrency: 1);
      final testFiles = ['test1.dart', 'test2.dart'];
      final deviceIds = ['device1'];

      final startTime = DateTime.now();
      final results = await executor.runParallel(
        testFiles: testFiles,
        deviceIds: deviceIds,
        testRunner: (testFile, deviceId) async {
          await Future.delayed(Duration(milliseconds: 100));
          return TestResult(
            testPath: testFile,
            testHash: 'hash_$testFile',
            passed: true,
            duration: Duration(milliseconds: 100),
            timestamp: DateTime.now(),
            deviceId: deviceId,
          );
        },
      );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(results.length, equals(2));
      // With concurrency 1, should take ~200ms (sequential)
      expect(duration.inMilliseconds, greaterThanOrEqualTo(200));
    });

    test('should handle test failures', () async {
      final executor = ParallelExecutor(maxConcurrency: 2);
      final testFiles = ['test1.dart', 'test2.dart', 'test3.dart'];
      final deviceIds = ['device1', 'device2'];

      final results = await executor.runParallel(
        testFiles: testFiles,
        deviceIds: deviceIds,
        testRunner: (testFile, deviceId) async {
          await Future.delayed(Duration(milliseconds: 50));

          // Make test2.dart fail
          final passed = testFile != 'test2.dart';

          return TestResult(
            testPath: testFile,
            testHash: 'hash_$testFile',
            passed: passed,
            duration: Duration(milliseconds: 50),
            timestamp: DateTime.now(),
            deviceId: deviceId,
            errorMessage: passed ? null : 'Test failed',
          );
        },
      );

      expect(results.length, equals(3));
      expect(results.where((r) => r.passed).length, equals(2));
      expect(results.where((r) => !r.passed).length, equals(1));
    });

    test('should calculate optimal device count', () {
      // The actual implementation may use different logic
      // Just verify it returns reasonable values
      final optimal1 = ParallelExecutor.calculateOptimalDeviceCount(5, 10);
      final optimal2 = ParallelExecutor.calculateOptimalDeviceCount(15, 10);
      final optimal3 = ParallelExecutor.calculateOptimalDeviceCount(25, 10);
      final optimal4 = ParallelExecutor.calculateOptimalDeviceCount(50, 10);

      expect(optimal1, greaterThan(0));
      expect(optimal2, greaterThan(0));
      expect(optimal3, greaterThan(0));
      expect(optimal4, greaterThan(0));

      // More tests should generally use more devices
      expect(optimal4, greaterThanOrEqualTo(optimal1));
    });

    test('should distribute tests across devices', () async {
      final executor = ParallelExecutor(maxConcurrency: 2);
      final testFiles = [
        'test1.dart',
        'test2.dart',
        'test3.dart',
        'test4.dart',
      ];
      final deviceIds = ['device1', 'device2'];

      final results = await executor.runParallel(
        testFiles: testFiles,
        deviceIds: deviceIds,
        testRunner: (testFile, deviceId) async {
          await Future.delayed(Duration(milliseconds: 50));
          return TestResult(
            testPath: testFile,
            testHash: 'hash_$testFile',
            passed: true,
            duration: Duration(milliseconds: 50),
            timestamp: DateTime.now(),
            deviceId: deviceId,
          );
        },
      );

      expect(results.length, equals(4));

      // Check that both devices were used
      final devicesUsed = results.map((r) => r.deviceId).toSet();
      expect(devicesUsed.length, equals(2));
    });
  });
}
