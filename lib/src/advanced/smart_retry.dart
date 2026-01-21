// smart_retry.dart - Intelligent retry mechanism for flaky tests
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// Smart retry mechanism with exponential backoff
class SmartRetry {
  static final SmartRetry _instance = SmartRetry._internal();
  factory SmartRetry() => _instance;
  SmartRetry._internal();

  bool _enabled = true;
  int _maxRetries = 3;
  Duration _initialDelay = const Duration(milliseconds: 500);
  double _backoffMultiplier = 2.0;
  List<Type> _retryableExceptions = [TestFailure, TimeoutException, StateError];

  final Map<String, int> _retryStats = {};
  final Map<String, List<String>> _failureReasons = {};

  /// Configure retry behavior
  void configure({
    bool? enabled,
    int? maxRetries,
    Duration? initialDelay,
    double? backoffMultiplier,
    List<Type>? retryableExceptions,
  }) {
    if (enabled != null) _enabled = enabled;
    if (maxRetries != null) _maxRetries = maxRetries;
    if (initialDelay != null) _initialDelay = initialDelay;
    if (backoffMultiplier != null) _backoffMultiplier = backoffMultiplier;
    if (retryableExceptions != null) _retryableExceptions = retryableExceptions;
  }

  /// Execute action with smart retry
  Future<T> retry<T>(
    String testName,
    Future<T> Function() action, {
    int? maxRetries,
    Duration? initialDelay,
    bool Function(dynamic error)? shouldRetry,
    Future<void> Function(int attempt)? onRetry,
  }) async {
    if (!_enabled) {
      return await action();
    }

    final retries = maxRetries ?? _maxRetries;
    final delay = initialDelay ?? _initialDelay;
    int attempt = 0;
    dynamic lastError;

    while (attempt <= retries) {
      try {
        if (attempt > 0) {
          print('🔄 Retry attempt $attempt/$retries for: $testName');

          // Call retry callback
          if (onRetry != null) {
            await onRetry(attempt);
          }

          // Wait with exponential backoff
          final waitTime = delay * pow(_backoffMultiplier, attempt - 1);
          await Future.delayed(waitTime);
        }

        final result = await action();

        // Success - record stats
        if (attempt > 0) {
          _recordSuccessfulRetry(testName, attempt);
          print(
            '✅ Test succeeded after $attempt ${attempt == 1 ? 'retry' : 'retries'}: $testName',
          );
        }

        return result;
      } catch (e, stackTrace) {
        lastError = e;

        // Check if should retry
        final shouldRetryError = shouldRetry?.call(e) ?? _isRetryableError(e);

        if (!shouldRetryError || attempt >= retries) {
          _recordFailedRetry(testName, attempt, e.toString());
          if (attempt > 0) {
            print(
              '❌ Test failed after $attempt ${attempt == 1 ? 'retry' : 'retries'}: $testName',
            );
          }
          rethrow;
        }

        _recordRetryAttempt(testName, e.toString());
        attempt++;
      }
    }

    // Should never reach here, but just in case
    throw lastError ?? Exception('Unknown error in retry logic');
  }

  /// Check if error is retryable
  bool _isRetryableError(dynamic error) {
    for (final type in _retryableExceptions) {
      if (error.runtimeType == type) return true;
    }

    // Check error messages for common flaky patterns
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('timeout') ||
        errorStr.contains('network') ||
        errorStr.contains('temporarily unavailable') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('element not found');
  }

  /// Record retry attempt
  void _recordRetryAttempt(String testName, String reason) {
    _retryStats[testName] = (_retryStats[testName] ?? 0) + 1;
    _failureReasons.putIfAbsent(testName, () => []).add(reason);
  }

  /// Record successful retry
  void _recordSuccessfulRetry(String testName, int attempts) {
    // Stats already recorded in _recordRetryAttempt
  }

  /// Record failed retry
  void _recordFailedRetry(String testName, int attempts, String finalError) {
    _failureReasons[testName]?.add('Final failure: $finalError');
  }

  /// Get retry statistics
  Map<String, dynamic> getRetryStats() {
    return {
      'total_tests_retried': _retryStats.length,
      'total_retry_attempts': _retryStats.values.fold<int>(
        0,
        (sum, count) => sum + count,
      ),
      'tests_by_retry_count': _retryStats,
      'most_flaky_tests': _getMostFlakyTests(),
    };
  }

  List<Map<String, dynamic>> _getMostFlakyTests() {
    final tests = _retryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return tests
        .take(5)
        .map(
          (entry) => {
            'test': entry.key,
            'retry_count': entry.value,
            'reasons': _failureReasons[entry.key] ?? [],
          },
        )
        .toList();
  }

  /// Generate retry report
  String generateReport() {
    if (_retryStats.isEmpty) {
      return '📊 No retries recorded';
    }

    final buffer = StringBuffer();
    buffer.writeln('═' * 80);
    buffer.writeln('🔄 SMART RETRY REPORT');
    buffer.writeln('═' * 80);
    buffer.writeln();

    final stats = getRetryStats();
    buffer.writeln('Total tests retried: ${stats['total_tests_retried']}');
    buffer.writeln('Total retry attempts: ${stats['total_retry_attempts']}');
    buffer.writeln();

    final flakyTests = stats['most_flaky_tests'] as List<Map<String, dynamic>>;
    if (flakyTests.isNotEmpty) {
      buffer.writeln('🎯 Most Flaky Tests:');
      for (final test in flakyTests) {
        buffer.writeln('  ${test['test']}: ${test['retry_count']} retries');
        final reasons = test['reasons'] as List<String>;
        if (reasons.isNotEmpty) {
          buffer.writeln('    Reasons: ${reasons.first}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('═' * 80);
    return buffer.toString();
  }

  /// Clear retry statistics
  void clearStats() {
    _retryStats.clear();
    _failureReasons.clear();
  }
}

/// Simple pow implementation
double pow(double base, int exponent) {
  if (exponent == 0) return 1.0;
  double result = base;
  for (int i = 1; i < exponent; i++) {
    result *= base;
  }
  return result;
}

/// Retry policy presets
class RetryPolicy {
  static const aggressive = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 200),
    backoffMultiplier: 1.5,
  );

  static const moderate = RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 2.0,
  );

  static const conservative = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.5,
  );

  static const immediate = RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(milliseconds: 100),
    backoffMultiplier: 1.0,
  );
}

/// Retry configuration
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;

  const RetryConfig({
    required this.maxRetries,
    required this.initialDelay,
    required this.backoffMultiplier,
  });
}
