// test_result_logger.dart - Comprehensive test result logging
import 'dart:io';
import 'dart:convert';
import '../test_suite/test_result.dart';
import '../test_suite/test_status.dart';

/// Test result log entry with full context
class TestResultLogEntry {
  final String testId;
  final String suiteName;
  final TestStatus status;
  final DateTime timestamp;
  final Duration duration;
  final String? error;
  final String? stackTrace;
  final Map<String, dynamic> metadata;
  final List<StepLogEntry> steps;
  final List<String> warnings;
  final String? screenshot;
  final Map<String, dynamic> environment;
  final String executor; // Who ran the test
  final String? buildNumber;
  final String? commitHash;

  // API test results
  final List<ApiTestResult> apiResults;

  TestResultLogEntry({
    required this.testId,
    required this.suiteName,
    required this.status,
    required this.timestamp,
    required this.duration,
    this.error,
    this.stackTrace,
    required this.metadata,
    required this.steps,
    required this.warnings,
    this.screenshot,
    required this.environment,
    required this.executor,
    this.buildNumber,
    this.commitHash,
    this.apiResults = const [],
  });

  Map<String, dynamic> toJson() => {
    'testId': testId,
    'suiteName': suiteName,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
    'duration': {
      'milliseconds': duration.inMilliseconds,
      'seconds': duration.inSeconds,
      'formatted': _formatDuration(duration),
    },
    'error': error,
    'stackTrace': stackTrace,
    'metadata': metadata,
    'steps': steps.map((s) => s.toJson()).toList(),
    'warnings': warnings,
    'screenshot': screenshot,
    'environment': environment,
    'executor': executor,
    'buildNumber': buildNumber,
    'commitHash': commitHash,
    'apiResults': apiResults.map((a) => a.toJson()).toList(),
    'summary': {
      'totalSteps': steps.length,
      'passedSteps': steps.where((s) => s.success).length,
      'failedSteps': steps.where((s) => !s.success).length,
      'totalApis': apiResults.length,
      'passedApis': apiResults.where((a) => a.passed).length,
      'failedApis': apiResults.where((a) => !a.passed).length,
    },
  };

  factory TestResultLogEntry.fromJson(Map<String, dynamic> json) {
    return TestResultLogEntry(
      testId: json['testId'],
      suiteName: json['suiteName'],
      status: TestStatus.values.firstWhere((e) => e.name == json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      duration: Duration(milliseconds: json['duration']['milliseconds']),
      error: json['error'],
      stackTrace: json['stackTrace'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      steps:
          (json['steps'] as List?)
              ?.map((s) => StepLogEntry.fromJson(s))
              .toList() ??
          [],
      warnings: List<String>.from(json['warnings'] ?? []),
      screenshot: json['screenshot'],
      environment: Map<String, dynamic>.from(json['environment'] ?? {}),
      executor: json['executor'],
      buildNumber: json['buildNumber'],
      commitHash: json['commitHash'],
      apiResults:
          (json['apiResults'] as List?)
              ?.map((a) => ApiTestResult.fromJson(a))
              .toList() ??
          [],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms';
    }
    return '${duration.inMilliseconds}ms';
  }
}

/// Individual step log entry
class StepLogEntry {
  final int stepNumber;
  final String action;
  final bool success;
  final String? error;
  final Duration duration;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  StepLogEntry({
    required this.stepNumber,
    required this.action,
    required this.success,
    this.error,
    required this.duration,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'action': action,
    'success': success,
    'error': error,
    'durationMs': duration.inMilliseconds,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StepLogEntry.fromJson(Map<String, dynamic> json) {
    return StepLogEntry(
      stepNumber: json['stepNumber'],
      action: json['action'],
      success: json['success'],
      error: json['error'],
      duration: Duration(milliseconds: json['durationMs']),
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// API test result entry
class ApiTestResult {
  final String apiId;
  final String url;
  final String method;
  final int? statusCode;
  final bool passed;
  final String? error;
  final Map<String, dynamic>? requestBody;
  final Map<String, dynamic>? responseBody;
  final Duration duration;

  ApiTestResult({
    required this.apiId,
    required this.url,
    required this.method,
    this.statusCode,
    required this.passed,
    this.error,
    this.requestBody,
    this.responseBody,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'apiId': apiId,
    'url': url,
    'method': method,
    'statusCode': statusCode,
    'passed': passed,
    'error': error,
    'requestBody': requestBody,
    'responseBody': responseBody,
    'durationMs': duration.inMilliseconds,
  };

  factory ApiTestResult.fromJson(Map<String, dynamic> json) {
    return ApiTestResult(
      apiId: json['apiId'],
      url: json['url'],
      method: json['method'],
      statusCode: json['statusCode'],
      passed: json['passed'],
      error: json['error'],
      requestBody: json['requestBody'],
      responseBody: json['responseBody'],
      duration: Duration(milliseconds: json['durationMs']),
    );
  }
}

/// Comprehensive test result logger - ALWAYS stores results
class TestResultLogger {
  final String logDirectory;

  TestResultLogger({this.logDirectory = 'test_results'});

  /// Log test result with comprehensive information - ALWAYS STORES RESULTS
  Future<String> logTestResult(
    TestResult result, {
    String? executor,
    String? buildNumber,
    String? commitHash,
    String? screenshot,
    List<ApiTestResult>? apiResults,
  }) async {
    try {
      // Ensure directories exist
      await _ensureDirectories();

      // Generate unique test ID
      final testId = _generateTestId(result.suiteName);

      // Get environment info
      final environment = await _getEnvironmentInfo();

      // Get executor info
      final executorName = executor ?? _getCurrentUser();

      // Create log entry - ALWAYS CREATE, even on failure
      final logEntry = TestResultLogEntry(
        testId: testId,
        suiteName: result.suiteName,
        status: result.status,
        timestamp: result.startTime,
        duration: result.totalDuration,
        error: result.error,
        stackTrace: result.error != null ? StackTrace.current.toString() : null,
        metadata: result.metadata,
        steps: _convertStepsToLogEntries(result),
        warnings: result.warnings,
        screenshot: screenshot,
        environment: environment,
        executor: executorName,
        buildNumber: buildNumber,
        commitHash: commitHash,
        apiResults: apiResults ?? [],
      );

      // Write log file - ALWAYS WRITE
      final logFilePath = await _writeLogFile(logEntry);

      print('📝 Test result logged: $logFilePath');
      print('   Test ID: $testId');
      print('   Status: ${result.status.name}');
      print('   Duration: ${result.totalDuration.inSeconds}s');
      print('   Steps: ${result.passedSteps}/${result.totalSteps}');
      if (apiResults != null && apiResults.isNotEmpty) {
        final passedApis = apiResults.where((a) => a.passed).length;
        print('   APIs: $passedApis/${apiResults.length}');
      }

      // Write to summary file
      await _writeSummaryFile(logEntry);

      // Write to daily log
      await _writeToDailyLog(logEntry);

      // Update statistics
      await _updateStatistics(logEntry);

      return testId;
    } catch (e, stackTrace) {
      print('❌ CRITICAL: Failed to log test result: $e');
      print('Stack trace: $stackTrace');

      // Try emergency backup
      try {
        await _emergencyBackup(result, executor);
      } catch (backupError) {
        print('❌ Emergency backup also failed: $backupError');
      }

      rethrow;
    }
  }

  /// Read test result log
  Future<TestResultLogEntry?> readTestResult(String testId) async {
    try {
      final logFilePath = '$logDirectory/$testId.json';
      final logFile = File(logFilePath);

      if (!await logFile.exists()) {
        print('❌ Test result not found: $testId');
        return null;
      }

      // Read and parse log file
      final logJson = jsonDecode(await logFile.readAsString());
      return TestResultLogEntry.fromJson(logJson);
    } catch (e) {
      print('❌ Failed to read test result: $e');
      return null;
    }
  }

  /// Get all test results with filtering
  Future<List<TestResultLogEntry>> getTestResults({
    TestStatus? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? suiteNameFilter,
    String? executorFilter,
    int? limit,
  }) async {
    try {
      final logDir = Directory(logDirectory);
      if (!await logDir.exists()) {
        return [];
      }

      final results = <TestResultLogEntry>[];

      await for (final entity in logDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final entry = TestResultLogEntry.fromJson(jsonDecode(content));

            // Apply filters
            if (statusFilter != null && entry.status != statusFilter) {
              continue;
            }

            if (startDate != null && entry.timestamp.isBefore(startDate)) {
              continue;
            }

            if (endDate != null && entry.timestamp.isAfter(endDate)) {
              continue;
            }

            if (suiteNameFilter != null &&
                !entry.suiteName.toLowerCase().contains(
                  suiteNameFilter.toLowerCase(),
                )) {
              continue;
            }

            if (executorFilter != null && entry.executor != executorFilter) {
              continue;
            }

            results.add(entry);

            if (limit != null && results.length >= limit) {
              break;
            }
          } catch (e) {
            print('⚠️  Skipping invalid log file: ${entity.path}');
          }
        }
      }

      // Sort by timestamp (newest first)
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return results;
    } catch (e) {
      print('❌ Failed to get test results: $e');
      return [];
    }
  }

  /// Generate comprehensive test execution report
  Future<String> generateReport({
    DateTime? startDate,
    DateTime? endDate,
    String? outputPath,
    bool includeDetails = true,
  }) async {
    try {
      final results = await getTestResults(
        startDate: startDate,
        endDate: endDate,
      );

      final report = StringBuffer();
      report.writeln(
        '╔═════════════════════════════════════════════════════════════════╗',
      );
      report.writeln(
        '║           FLUTTER TEST PILOT - TEST EXECUTION REPORT            ║',
      );
      report.writeln(
        '╚═════════════════════════════════════════════════════════════════╝',
      );
      report.writeln('');
      report.writeln('Generated: ${_formatDateTime(DateTime.now())}');
      if (startDate != null) {
        report.writeln('Start Date: ${_formatDateTime(startDate)}');
      }
      if (endDate != null) {
        report.writeln('End Date: ${_formatDateTime(endDate)}');
      }
      report.writeln('');
      report.writeln('═' * 65);
      report.writeln('SUMMARY');
      report.writeln('═' * 65);
      report.writeln('');

      final totalTests = results.length;
      final passed = results.where((r) => r.status == TestStatus.passed).length;
      final failed = results.where((r) => r.status == TestStatus.failed).length;
      final skipped = results
          .where((r) => r.status == TestStatus.skipped)
          .length;

      report.writeln('Total Tests:     $totalTests');
      report.writeln(
        '✅ Passed:       $passed (${_percentage(passed, totalTests).toStringAsFixed(1)}%)',
      );
      report.writeln(
        '❌ Failed:       $failed (${_percentage(failed, totalTests).toStringAsFixed(1)}%)',
      );
      report.writeln(
        '⏭️  Skipped:      $skipped (${_percentage(skipped, totalTests).toStringAsFixed(1)}%)',
      );
      report.writeln('');

      // Calculate total steps and APIs
      var totalSteps = 0;
      var passedSteps = 0;
      var totalApis = 0;
      var passedApis = 0;
      var totalDuration = Duration.zero;

      for (final result in results) {
        totalSteps += result.steps.length;
        passedSteps += result.steps.where((s) => s.success).length;
        totalApis += result.apiResults.length;
        passedApis += result.apiResults.where((a) => a.passed).length;
        totalDuration += result.duration;
      }

      report.writeln('Steps Executed:  $totalSteps');
      report.writeln(
        'Steps Passed:    $passedSteps (${_percentage(passedSteps, totalSteps).toStringAsFixed(1)}%)',
      );
      report.writeln('');
      report.writeln('API Tests:       $totalApis');
      report.writeln(
        'APIs Passed:     $passedApis (${_percentage(passedApis, totalApis).toStringAsFixed(1)}%)',
      );
      report.writeln('');
      report.writeln('Total Duration:  ${_formatDuration(totalDuration)}');
      report.writeln(
        'Avg Duration:    ${totalTests > 0 ? _formatDuration(Duration(milliseconds: totalDuration.inMilliseconds ~/ totalTests)) : '0ms'}',
      );
      report.writeln('');

      // Failed tests section
      if (failed > 0) {
        report.writeln('═' * 65);
        report.writeln('FAILED TESTS ($failed)');
        report.writeln('═' * 65);
        report.writeln('');

        final failedTests = results.where((r) => r.status == TestStatus.failed);
        for (final test in failedTests) {
          report.writeln('❌ ${test.suiteName}');
          report.writeln('   Test ID:    ${test.testId}');
          report.writeln('   Timestamp:  ${_formatDateTime(test.timestamp)}');
          report.writeln('   Duration:   ${_formatDuration(test.duration)}');
          report.writeln('   Executor:   ${test.executor}');
          report.writeln(
            '   Steps:      ${test.steps.where((s) => s.success).length}/${test.steps.length} passed',
          );

          if (test.error != null) {
            report.writeln('   Error:      ${test.error}');
          }

          if (includeDetails && test.steps.isNotEmpty) {
            final failedSteps = test.steps.where((s) => !s.success);
            if (failedSteps.isNotEmpty) {
              report.writeln('   Failed Steps:');
              for (final step in failedSteps) {
                report.writeln(
                  '     - Step ${step.stepNumber}: ${step.action}',
                );
                if (step.error != null) {
                  report.writeln('       Error: ${step.error}');
                }
              }
            }
          }

          report.writeln('');
        }
      }

      // Passed tests section
      if (passed > 0 && includeDetails) {
        report.writeln('═' * 65);
        report.writeln('PASSED TESTS ($passed)');
        report.writeln('═' * 65);
        report.writeln('');

        final passedTests = results.where((r) => r.status == TestStatus.passed);
        for (final test in passedTests) {
          report.writeln('✅ ${test.suiteName}');
          report.writeln('   Test ID:    ${test.testId}');
          report.writeln('   Timestamp:  ${_formatDateTime(test.timestamp)}');
          report.writeln('   Duration:   ${_formatDuration(test.duration)}');
          report.writeln('   Executor:   ${test.executor}');
          report.writeln(
            '   Steps:      ${test.steps.length}/${test.steps.length} passed',
          );
          if (test.apiResults.isNotEmpty) {
            report.writeln(
              '   APIs:       ${test.apiResults.where((a) => a.passed).length}/${test.apiResults.length} passed',
            );
          }
          report.writeln('');
        }
      }

      // Test statistics by executor
      final executors = <String, Map<String, int>>{};
      for (final result in results) {
        executors.putIfAbsent(
          result.executor,
          () => {'total': 0, 'passed': 0, 'failed': 0, 'skipped': 0},
        );
        executors[result.executor]!['total'] =
            executors[result.executor]!['total']! + 1;
        executors[result.executor]![result.status.name] =
            (executors[result.executor]![result.status.name] ?? 0) + 1;
      }

      if (executors.isNotEmpty) {
        report.writeln('═' * 65);
        report.writeln('STATISTICS BY EXECUTOR');
        report.writeln('═' * 65);
        report.writeln('');

        for (final entry in executors.entries) {
          final executor = entry.key;
          final stats = entry.value;
          final total = stats['total']!;
          final passed = stats['passed'] ?? 0;
          final failed = stats['failed'] ?? 0;

          report.writeln('👤 $executor');
          report.writeln('   Total:   $total');
          report.writeln(
            '   Passed:  $passed (${_percentage(passed, total).toStringAsFixed(1)}%)',
          );
          report.writeln(
            '   Failed:  $failed (${_percentage(failed, total).toStringAsFixed(1)}%)',
          );
          report.writeln('');
        }
      }

      report.writeln('═' * 65);
      report.writeln('END OF REPORT');
      report.writeln('═' * 65);

      final reportContent = report.toString();

      // Write to file if path provided
      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(reportContent);
        print('📄 Report saved: $outputPath');
      }

      return reportContent;
    } catch (e) {
      print('❌ Failed to generate report: $e');
      rethrow;
    }
  }

  /// Get test statistics
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final results = await getTestResults(
      startDate: startDate,
      endDate: endDate,
    );

    final totalTests = results.length;
    final passed = results.where((r) => r.status == TestStatus.passed).length;
    final failed = results.where((r) => r.status == TestStatus.failed).length;
    final skipped = results.where((r) => r.status == TestStatus.skipped).length;

    var totalSteps = 0;
    var passedSteps = 0;
    var totalApis = 0;
    var passedApis = 0;
    var totalDuration = Duration.zero;

    for (final result in results) {
      totalSteps += result.steps.length;
      passedSteps += result.steps.where((s) => s.success).length;
      totalApis += result.apiResults.length;
      passedApis += result.apiResults.where((a) => a.passed).length;
      totalDuration += result.duration;
    }

    return {
      'totalTests': totalTests,
      'passedTests': passed,
      'failedTests': failed,
      'skippedTests': skipped,
      'passRate': totalTests > 0 ? _percentage(passed, totalTests) : 0.0,
      'totalSteps': totalSteps,
      'passedSteps': passedSteps,
      'failedSteps': totalSteps - passedSteps,
      'stepPassRate': totalSteps > 0
          ? _percentage(passedSteps, totalSteps)
          : 0.0,
      'totalApis': totalApis,
      'passedApis': passedApis,
      'failedApis': totalApis - passedApis,
      'apiPassRate': totalApis > 0 ? _percentage(passedApis, totalApis) : 0.0,
      'totalDuration': totalDuration.inMilliseconds,
      'averageDuration': totalTests > 0
          ? totalDuration.inMilliseconds ~/ totalTests
          : 0,
    };
  }

  // Private helper methods

  Future<void> _ensureDirectories() async {
    await Directory(logDirectory).create(recursive: true);
    await Directory('$logDirectory/daily').create(recursive: true);
    await Directory('$logDirectory/emergency').create(recursive: true);
    await Directory('$logDirectory/reports').create(recursive: true);
  }

  String _generateTestId(String suiteName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitized = suiteName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    return '${sanitized}_$timestamp';
  }

  Future<String> _writeLogFile(TestResultLogEntry entry) async {
    final filePath = '$logDirectory/${entry.testId}.json';
    final file = File(filePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entry.toJson()),
    );
    return filePath;
  }

  Future<void> _writeSummaryFile(TestResultLogEntry entry) async {
    final summaryPath = '$logDirectory/test_summary.txt';
    final file = File(summaryPath);

    final icon = entry.status == TestStatus.passed
        ? '✅'
        : entry.status == TestStatus.failed
        ? '❌'
        : '⏭️';

    final passedSteps = entry.steps.where((s) => s.success).length;
    final passedApis = entry.apiResults.where((a) => a.passed).length;

    final summary =
        '''
$icon [${_formatDateTime(entry.timestamp)}] ${entry.status.name.toUpperCase()} - ${entry.suiteName}
   Test ID:    ${entry.testId}
   Duration:   ${_formatDuration(entry.duration)}
   Executor:   ${entry.executor}
   Steps:      $passedSteps/${entry.steps.length} passed
   ${entry.apiResults.isNotEmpty ? 'APIs:       $passedApis/${entry.apiResults.length} passed' : ''}
   ${entry.error != null ? 'Error:      ${entry.error}' : ''}
   ${entry.warnings.isNotEmpty ? 'Warnings:   ${entry.warnings.length}' : ''}

''';

    await file.writeAsString(summary, mode: FileMode.append);
  }

  Future<void> _writeToDailyLog(TestResultLogEntry entry) async {
    final date = entry.timestamp.toIso8601String().split('T')[0];
    final dailyLogPath = '$logDirectory/daily/$date.log';
    final file = File(dailyLogPath);

    final passedSteps = entry.steps.where((s) => s.success).length;
    final logLine =
        '${_formatDateTime(entry.timestamp)} | ${entry.status.name.padRight(8)} | ${entry.suiteName.padRight(40)} | Steps: $passedSteps/${entry.steps.length} | ${entry.executor}\n';

    await file.writeAsString(logLine, mode: FileMode.append);
  }

  Future<void> _updateStatistics(TestResultLogEntry entry) async {
    try {
      final statsPath = '$logDirectory/statistics.json';
      final statsFile = File(statsPath);

      Map<String, dynamic> stats = {};
      if (await statsFile.exists()) {
        stats = jsonDecode(await statsFile.readAsString());
      }

      // Update counts
      stats['totalTests'] = (stats['totalTests'] ?? 0) + 1;
      stats['passed'] =
          (stats['passed'] ?? 0) + (entry.status == TestStatus.passed ? 1 : 0);
      stats['failed'] =
          (stats['failed'] ?? 0) + (entry.status == TestStatus.failed ? 1 : 0);
      stats['skipped'] =
          (stats['skipped'] ?? 0) +
          (entry.status == TestStatus.skipped ? 1 : 0);

      // Update step counts
      stats['totalSteps'] = (stats['totalSteps'] ?? 0) + entry.steps.length;
      stats['passedSteps'] =
          (stats['passedSteps'] ?? 0) +
          entry.steps.where((s) => s.success).length;

      // Update API counts
      stats['totalApis'] = (stats['totalApis'] ?? 0) + entry.apiResults.length;
      stats['passedApis'] =
          (stats['passedApis'] ?? 0) +
          entry.apiResults.where((a) => a.passed).length;

      stats['lastUpdated'] = DateTime.now().toIso8601String();

      await statsFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(stats),
      );
    } catch (e) {
      print('⚠️  Failed to update statistics: $e');
    }
  }

  Future<void> _emergencyBackup(TestResult result, String? executor) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '$logDirectory/emergency/backup_$timestamp.txt';
      final file = File(backupPath);

      final backup =
          '''
EMERGENCY BACKUP - Test Result Storage Failed
============================================
Suite Name: ${result.suiteName}
Status:     ${result.status.name}
Start Time: ${result.startTime}
Duration:   ${result.totalDuration}
Executor:   ${executor ?? 'unknown'}
Error:      ${result.error ?? 'none'}
Steps:      ${result.totalSteps}
Passed:     ${result.passedSteps}
Failed:     ${result.failedSteps}
Warnings:   ${result.warnings.length}

${result.warnings.isNotEmpty ? 'Warnings:\n${result.warnings.join('\n')}\n' : ''}

Metadata:
${result.metadata.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}
''';

      await file.writeAsString(backup);
      print('⚠️  Emergency backup saved: $backupPath');
    } catch (e) {
      print('❌ Emergency backup failed: $e');
    }
  }

  List<StepLogEntry> _convertStepsToLogEntries(TestResult result) {
    final entries = <StepLogEntry>[];
    var stepNumber = 1;

    for (final step in result.allResults) {
      entries.add(
        StepLogEntry(
          stepNumber: stepNumber++,
          action: step.message ?? 'Unknown action',
          success: step.success,
          error: step.error,
          duration: step.duration,
          metadata: step.data,
          timestamp: DateTime.now(),
        ),
      );
    }

    return entries;
  }

  Future<Map<String, dynamic>> _getEnvironmentInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'dart_version': Platform.version,
      'hostname': Platform.localHostname,
      'processors': Platform.numberOfProcessors,
      'environment': {
        'CI': Platform.environment['CI'],
        'USER': Platform.environment['USER'],
        'HOME': Platform.environment['HOME'],
      },
    };
  }

  String _getCurrentUser() {
    return Platform.environment['USER'] ??
        Platform.environment['USERNAME'] ??
        Platform.environment['LOGNAME'] ??
        'unknown_user';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms';
    }
    return '${duration.inMilliseconds}ms';
  }

  double _percentage(int value, int total) {
    if (total == 0) return 0.0;
    return (value / total * 100);
  }
}
