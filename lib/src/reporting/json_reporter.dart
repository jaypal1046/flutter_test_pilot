import 'dart:convert';
import 'dart:io';

import '../test_suite/test_result.dart';
import '../test_suite/test_status.dart';
import '../test_suite/step_result.dart';

/// Reporter that outputs test results in JSON format for CI/CD integration
class JsonReporter {
  final bool prettyPrint;
  final String? outputFile;
  final bool includeMetadata;
  final bool includeStepDetails;

  const JsonReporter({
    this.prettyPrint = true,
    this.outputFile,
    this.includeMetadata = true,
    this.includeStepDetails = true,
  });

  /// Generate JSON report for a single test result
  Map<String, dynamic> generateTestReport(TestResult result) {
    return {
      'testSuite': {
        'name': result.suiteName,
        'status': result.status.name,
        'startTime': result.startTime.toIso8601String(),
        'endTime': result.endTime?.toIso8601String(),
        'duration': {
          'totalMs': result.totalDuration.inMilliseconds,
          'totalSeconds': result.totalDuration.inSeconds,
        },
        'error': result.error,
        'cleanupError': result.cleanupError,
        if (includeStepDetails) ...{
          'phases': {
            'setup': _convertStepResults(result.setupResults),
            'test': _convertStepResults(result.testResults),
            'cleanup': _convertStepResults(result.cleanupResults),
          },
        },
        'summary': {
          'totalSteps':
              result.setupResults.length +
              result.testResults.length +
              result.cleanupResults.length,
          'successfulSteps': _countSuccessfulSteps(result),
          'failedSteps': _countFailedSteps(result),
        },
      },
      'timestamp': DateTime.now().toIso8601String(),
      'reportVersion': '1.0.0',
    };
  }

  /// Generate JSON report for a test group
  Map<String, dynamic> generateGroupReport(
    String groupName,
    List<TestResult> results, {
    String? description,
    bool stopOnFailure = false,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    final passed = results.where((r) => r.status == TestStatus.passed).length;
    final failed = results.where((r) => r.status == TestStatus.failed).length;
    final skipped = results.where((r) => r.status == TestStatus.skipped).length;
    final totalDuration = results.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.totalDuration,
    );

    return {
      'testGroup': {
        'name': groupName,
        'description': description,
        'configuration': {
          'stopOnFailure': stopOnFailure,
          'timeout': timeout?.inMilliseconds,
          if (includeMetadata && metadata != null) 'metadata': metadata,
        },
        'summary': {
          'totalTests': results.length,
          'passed': passed,
          'failed': failed,
          'skipped': skipped,
          'successRate': results.isEmpty
              ? 0.0
              : (passed / results.length * 100),
          'duration': {
            'totalMs': totalDuration.inMilliseconds,
            'totalSeconds': totalDuration.inSeconds,
            'averageMs': results.isEmpty
                ? 0
                : totalDuration.inMilliseconds ~/ results.length,
          },
        },
        'tests': results.map((result) => _convertTestResult(result)).toList(),
        'failedTests': results
            .where((r) => r.status == TestStatus.failed)
            .map(
              (r) => {
                'name': r.suiteName,
                'error': r.error,
                'duration': r.totalDuration.inMilliseconds,
              },
            )
            .toList(),
      },
      'timestamp': DateTime.now().toIso8601String(),
      'reportVersion': '1.0.0',
    };
  }

  /// Generate comprehensive execution report
  Map<String, dynamic> generateExecutionReport(
    List<TestResult> allResults, {
    String? executionId,
    Map<String, dynamic>? environment,
    Map<String, dynamic>? configuration,
  }) {
    final passed = allResults
        .where((r) => r.status == TestStatus.passed)
        .length;
    final failed = allResults
        .where((r) => r.status == TestStatus.failed)
        .length;
    final skipped = allResults
        .where((r) => r.status == TestStatus.skipped)
        .length;
    final totalDuration = allResults.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.totalDuration,
    );

    final report = {
      'testExecution': {
        'id': executionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'startTime': allResults.isEmpty
            ? null
            : allResults
                  .map((r) => r.startTime)
                  .reduce((a, b) => a.isBefore(b) ? a : b)
                  .toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'summary': {
          'totalTests': allResults.length,
          'passed': passed,
          'failed': failed,
          'skipped': skipped,
          'successRate': allResults.isEmpty
              ? 0.0
              : (passed / allResults.length * 100),
          'duration': {
            'totalMs': totalDuration.inMilliseconds,
            'totalSeconds': totalDuration.inSeconds,
            'averageMs': allResults.isEmpty
                ? 0
                : totalDuration.inMilliseconds ~/ allResults.length,
          },
        },
        'results': allResults
            .map((result) => _convertTestResult(result))
            .toList(),
        'statistics': {
          'fastestTest': _getFastestTest(allResults),
          'slowestTest': _getSlowestTest(allResults),
          'mostSteps': _getTestWithMostSteps(allResults),
          'errorPatterns': _analyzeErrorPatterns(allResults),
        },
      },
      if (environment != null) 'environment': environment,
      if (configuration != null) 'configuration': configuration,
      'timestamp': DateTime.now().toIso8601String(),
      'reportVersion': '1.0.0',
    };

    return report;
  }

  /// Save report to file or print to console
  Future<void> outputReport(Map<String, dynamic> report) async {
    final jsonString = prettyPrint
        ? const JsonEncoder.withIndent('  ').convert(report)
        : jsonEncode(report);

    if (outputFile != null) {
      final file = File(outputFile!);
      await file.writeAsString(jsonString);
      print('📄 JSON report saved to: $outputFile');
    } else {
      print(jsonString);
    }
  }

  /// Save multiple reports (useful for CI/CD artifacts)
  Future<void> saveReports(
    List<TestResult> results, {
    String? baseFilename,
    Map<String, dynamic>? environment,
  }) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final base = baseFilename ?? 'test-report-$timestamp';

    // Individual test reports
    for (int i = 0; i < results.length; i++) {
      final report = generateTestReport(results[i]);
      final filename = '${base}-test-${i + 1}.json';
      await JsonReporter(
        outputFile: filename,
        prettyPrint: prettyPrint,
      ).outputReport(report);
    }

    // Execution summary report
    final summaryReport = generateExecutionReport(
      results,
      environment: environment,
    );
    final summaryFilename = '$base-summary.json';
    await JsonReporter(
      outputFile: summaryFilename,
      prettyPrint: prettyPrint,
    ).outputReport(summaryReport);
  }

  /// Convert StepResult list to JSON-serializable format
  List<Map<String, dynamic>> _convertStepResults(List<StepResult> steps) {
    return steps
        .map(
          (step) => {
            'success': step.success,
            'duration': step.duration.inMilliseconds,
            'message': step.message,
            'error': step.error,
            if (step.data != null) 'data': step.data,
          },
        )
        .toList();
  }

  /// Convert TestResult to JSON-serializable format
  Map<String, dynamic> _convertTestResult(TestResult result) {
    return {
      'name': result.suiteName,
      'status': result.status.name,
      'startTime': result.startTime.toIso8601String(),
      'endTime': result.endTime?.toIso8601String(),
      'duration': result.totalDuration.inMilliseconds,
      'error': result.error,
      'cleanupError': result.cleanupError,
      if (includeStepDetails)
        'stepCounts': {
          'setup': result.setupResults.length,
          'test': result.testResults.length,
          'cleanup': result.cleanupResults.length,
          'successful': _countSuccessfulSteps(result),
          'failed': _countFailedSteps(result),
        },
    };
  }

  /// Count successful steps in a test result
  int _countSuccessfulSteps(TestResult result) {
    return result.setupResults.where((s) => s.success).length +
        result.testResults.where((s) => s.success).length +
        result.cleanupResults.where((s) => s.success).length;
  }

  /// Count failed steps in a test result
  int _countFailedSteps(TestResult result) {
    return result.setupResults.where((s) => !s.success).length +
        result.testResults.where((s) => !s.success).length +
        result.cleanupResults.where((s) => !s.success).length;
  }

  /// Get the fastest test from results
  Map<String, dynamic>? _getFastestTest(List<TestResult> results) {
    if (results.isEmpty) return null;

    final fastest = results.reduce(
      (a, b) => a.totalDuration.inMilliseconds < b.totalDuration.inMilliseconds
          ? a
          : b,
    );

    return {
      'name': fastest.suiteName,
      'duration': fastest.totalDuration.inMilliseconds,
    };
  }

  /// Get the slowest test from results
  Map<String, dynamic>? _getSlowestTest(List<TestResult> results) {
    if (results.isEmpty) return null;

    final slowest = results.reduce(
      (a, b) => a.totalDuration.inMilliseconds > b.totalDuration.inMilliseconds
          ? a
          : b,
    );

    return {
      'name': slowest.suiteName,
      'duration': slowest.totalDuration.inMilliseconds,
    };
  }

  /// Get test with most steps
  Map<String, dynamic>? _getTestWithMostSteps(List<TestResult> results) {
    if (results.isEmpty) return null;

    final mostSteps = results.reduce((a, b) {
      final aSteps =
          a.setupResults.length +
          a.testResults.length +
          a.cleanupResults.length;
      final bSteps =
          b.setupResults.length +
          b.testResults.length +
          b.cleanupResults.length;
      return aSteps > bSteps ? a : b;
    });

    final stepCount =
        mostSteps.setupResults.length +
        mostSteps.testResults.length +
        mostSteps.cleanupResults.length;

    return {'name': mostSteps.suiteName, 'stepCount': stepCount};
  }

  /// Analyze common error patterns
  Map<String, int> _analyzeErrorPatterns(List<TestResult> results) {
    final errorPatterns = <String, int>{};

    for (final result in results) {
      if (result.error != null) {
        // Extract error type from error message
        final error = result.error!;
        String pattern;

        if (error.contains('TimeoutException')) {
          pattern = 'timeout';
        } else if (error.contains('AssertionError')) {
          pattern = 'assertion';
        } else if (error.contains('StateError')) {
          pattern = 'state';
        } else if (error.contains('ArgumentError')) {
          pattern = 'argument';
        } else if (error.contains('Exception')) {
          pattern = 'exception';
        } else {
          pattern = 'unknown';
        }

        errorPatterns[pattern] = (errorPatterns[pattern] ?? 0) + 1;
      }
    }

    return errorPatterns;
  }

  /// Create a JUnit XML compatible report (alternative format)
  String generateJUnitXml(List<TestResult> results) {
    final totalTests = results.length;
    final failures = results.where((r) => r.status == TestStatus.failed).length;
    final totalTime = results
        .fold<Duration>(
          Duration.zero,
          (sum, result) => sum + result.totalDuration,
        )
        .inSeconds;

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<testsuite name="FlutterTestPilot" tests="$totalTests" failures="$failures" time="$totalTime">',
    );

    for (final result in results) {
      final time = result.totalDuration.inSeconds;
      buffer.writeln('  <testcase name="${result.suiteName}" time="$time">');

      if (result.status == TestStatus.failed) {
        buffer.writeln(
          '    <failure message="${result.error ?? 'Unknown error'}">',
        );
        buffer.writeln(
          '      ${result.error ?? 'Test failed without specific error message'}',
        );
        buffer.writeln('    </failure>');
      }

      buffer.writeln('  </testcase>');
    }

    buffer.writeln('</testsuite>');
    return buffer.toString();
  }
}
