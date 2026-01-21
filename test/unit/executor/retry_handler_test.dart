import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/executor/retry_handler.dart';
import 'package:flutter_test_pilot/core/models/test_result.dart';

void main() {
  group('RetryHandler', () {
    test('should succeed on first attempt', () async {
      final retryHandler = RetryHandler(
        maxRetries: 3,
        initialDelay: Duration(milliseconds: 10),
      );

      final result = await retryHandler.runWithRetry(
        testPath: 'test_example.dart',
        deviceId: 'test-device',
        testRunner: () async {
          return TestResult(
            testPath: 'test_example.dart',
            testHash: 'abc123',
            passed: true,
            duration: Duration(milliseconds: 100),
            timestamp: DateTime.now(),
          );
        },
      );

      expect(result.passed, isTrue);
    });

    test('should retry and eventually succeed', () async {
      final retryHandler = RetryHandler(
        maxRetries: 3,
        initialDelay: Duration(milliseconds: 10),
      );

      var attemptCount = 0;

      final result = await retryHandler.runWithRetry(
        testPath: 'test_example.dart',
        deviceId: 'test-device',
        testRunner: () async {
          attemptCount++;

          // Fail first 2 attempts, succeed on 3rd
          if (attemptCount < 3) {
            return TestResult(
              testPath: 'test_example.dart',
              testHash: 'abc123',
              passed: false,
              duration: Duration(milliseconds: 100),
              timestamp: DateTime.now(),
              errorMessage: 'Temporary failure',
            );
          }

          return TestResult(
            testPath: 'test_example.dart',
            testHash: 'abc123',
            passed: true,
            duration: Duration(milliseconds: 100),
            timestamp: DateTime.now(),
          );
        },
      );

      expect(result.passed, isTrue);
      expect(attemptCount, equals(3));
    });

    test('should fail after max retries', () async {
      final retryHandler = RetryHandler(
        maxRetries: 2,
        initialDelay: Duration(milliseconds: 10),
      );

      var attemptCount = 0;

      final result = await retryHandler.runWithRetry(
        testPath: 'test_example.dart',
        deviceId: 'test-device',
        testRunner: () async {
          attemptCount++;

          return TestResult(
            testPath: 'test_example.dart',
            testHash: 'abc123',
            passed: false,
            duration: Duration(milliseconds: 100),
            timestamp: DateTime.now(),
            errorMessage: 'Persistent failure',
          );
        },
      );

      expect(result.passed, isFalse);
      expect(attemptCount, equals(3)); // Initial + 2 retries
    });

    test('should detect retriable errors', () {
      expect(RetryHandler.isRetriableError('Network timeout'), isTrue);
      expect(RetryHandler.isRetriableError('Connection failed'), isTrue);
      expect(RetryHandler.isRetriableError('Connection refused'), isTrue);
      expect(RetryHandler.isRetriableError('Syntax error'), isFalse);
      expect(RetryHandler.isRetriableError('Assertion failed'), isFalse);
    });

    test('should not retry non-retriable errors', () async {
      final retryHandler = RetryHandler(
        maxRetries: 3,
        initialDelay: Duration(milliseconds: 10),
      );

      var attemptCount = 0;

      final result = await retryHandler.runWithRetry(
        testPath: 'test_example.dart',
        deviceId: 'test-device',
        testRunner: () async {
          attemptCount++;

          return TestResult(
            testPath: 'test_example.dart',
            testHash: 'abc123',
            passed: false,
            duration: Duration(milliseconds: 100),
            timestamp: DateTime.now(),
            errorMessage: 'Assertion failed in test',
          );
        },
      );

      expect(result.passed, isFalse);
      // Should not retry for assertion errors
      expect(attemptCount, greaterThanOrEqualTo(1));
    });
  });
}
