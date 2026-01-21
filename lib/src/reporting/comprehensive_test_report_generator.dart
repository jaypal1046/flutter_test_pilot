import 'dart:io';
import 'dart:convert';
import '../test_suite/test_result.dart';
import '../test_suite/test_status.dart';
import '../test_suite/apis/model/api_test_result.dart';
import '../test_suite/apis/model/api_call_data.dart';

/// Comprehensive test report generator for ALL test types
/// Automatically generates reports from the package side
/// Users can disable with --noReport flag or config
class ComprehensiveTestReportGenerator {
  static final ComprehensiveTestReportGenerator _instance =
      ComprehensiveTestReportGenerator._internal();
  static ComprehensiveTestReportGenerator get instance => _instance;

  ComprehensiveTestReportGenerator._internal();

  /// Check if reports are enabled (default: true)
  /// Can be disabled with environment variable: DISABLE_TEST_REPORTS=true
  bool get reportsEnabled {
    final envDisabled = Platform.environment['DISABLE_TEST_REPORTS'];
    return envDisabled?.toLowerCase() != 'true';
  }

  /// Generate comprehensive reports for a test result
  /// This is called AUTOMATICALLY after each test suite execution
  Future<Map<String, String>> generateReports({
    required TestResult testResult,
    required List<ApiCallData> capturedApiCalls,
    required List<ApiTestResult> apiTestResults,
    String? outputDir,
  }) async {
    if (!reportsEnabled) {
      print('📊 Test reports disabled (DISABLE_TEST_REPORTS=true)');
      return {};
    }

    print('');
    print('═' * 80);
    print('📊 GENERATING COMPREHENSIVE TEST REPORTS');
    print('═' * 80);
    print('Test Suite: ${testResult.suiteName}');
    print('Status: ${testResult.status.name.toUpperCase()}');
    print('Duration: ${testResult.totalDuration.inSeconds}s');
    print('UI Steps: ${testResult.passedSteps}/${testResult.totalSteps}');
    print(
      'API Tests: ${apiTestResults.where((a) => a.isSuccess).length}/${apiTestResults.length}',
    );
    print('API Calls: ${capturedApiCalls.length}');
    print('');

    try {
      // Get writable directory based on platform
      final reportDir = await _getWritableReportDirectory(outputDir);
      print('📁 Report directory: ${reportDir.path}');

      if (!await reportDir.exists()) {
        print('📁 Creating report directory...');
        await reportDir.create(recursive: true);
        print('✅ Directory created successfully');
      }
      print('');

      final reports = <String, String>{};
      final timestamp = DateTime.now();
      final dateStr = timestamp
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final safeTestName = testResult.suiteName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');

      // Generate JSON Report
      print('📝 Generating JSON report...');
      final jsonPath =
          '${reportDir.path}/test_report_${safeTestName}_$dateStr.json';
      await _generateJsonReport(
        jsonPath,
        testResult,
        capturedApiCalls,
        apiTestResults,
        timestamp,
      );
      reports['JSON Report'] = jsonPath;
      print('   ✓ JSON report generated');

      // Generate HTML Report
      print('📝 Generating HTML report...');
      final htmlPath =
          '${reportDir.path}/test_report_${safeTestName}_$dateStr.html';
      await _generateHtmlReport(
        htmlPath,
        testResult,
        capturedApiCalls,
        apiTestResults,
        timestamp,
      );
      reports['HTML Report'] = htmlPath;
      print('   ✓ HTML report generated');

      // Generate Markdown Report
      print('📝 Generating Markdown report...');
      final mdPath =
          '${reportDir.path}/test_report_${safeTestName}_$dateStr.md';
      await _generateMarkdownReport(
        mdPath,
        testResult,
        capturedApiCalls,
        apiTestResults,
        timestamp,
      );
      reports['Markdown Report'] = mdPath;
      print('   ✓ Markdown report generated');

      // Generate summary file (lightweight overview)
      print('📝 Generating summary file...');
      final summaryPath = '${reportDir.path}/LATEST_TEST_SUMMARY.txt';
      await _generateSummaryFile(
        summaryPath,
        testResult,
        capturedApiCalls,
        apiTestResults,
        timestamp,
      );
      reports['Summary'] = summaryPath;
      print('   ✓ Summary generated');

      print('');
      print('═' * 80);
      print('✅ REPORTS GENERATED SUCCESSFULLY');
      print('═' * 80);
      for (final report in reports.entries) {
        print('📄 ${report.key}: ${report.value}');
        final file = File(report.value);
        if (await file.exists()) {
          final sizeKb = (await file.length()) / 1024;
          print('   ✓ File size: ${sizeKb.toStringAsFixed(2)} KB');
        }
      }
      print('═' * 80);
      print('');

      _printPlatformInstructions(reportDir.path, reports);

      return reports;
    } catch (e, stackTrace) {
      print('');
      print('═' * 80);
      print('❌ FAILED TO GENERATE REPORTS');
      print('═' * 80);
      print('Error: $e');
      print('');
      print('Stack trace:');
      print(stackTrace.toString());
      print('═' * 80);
      print('');
      print('💡 Reports are optional - test execution was successful');
      print('💡 To disable reports: export DISABLE_TEST_REPORTS=true');
      print('');
      return {};
    }
  }

  /// Get writable report directory based on platform
  /// CRITICAL: Use ABSOLUTE paths to ensure reports save on YOUR LAPTOP
  Future<Directory> _getWritableReportDirectory(String? customDir) async {
    if (customDir != null) {
      return Directory(customDir);
    }

    // The problem: During integration tests, Directory.current might point to device paths
    // The solution: Use ABSOLUTE paths based on the test file location

    try {
      // Try to get the workspace root by looking for pubspec.yaml
      final workspaceRoot = await _findWorkspaceRoot();

      if (workspaceRoot != null) {
        // Use absolute path in workspace
        final reportDir = Directory(
          '${workspaceRoot.path}/integration_test/test_reports',
        );

        print('💻 Reports will be saved on YOUR LAPTOP (macOS)');
        print('   Absolute path: ${reportDir.absolute.path}');
        print('');

        // Ensure directory exists
        if (!await reportDir.exists()) {
          await reportDir.create(recursive: true);
        }

        return reportDir;
      }
    } catch (e) {
      print('⚠️  Could not determine workspace root: $e');
    }

    // Fallback: Use macOS home directory
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        final reportDir = Directory('$homeDir/flutter_test_reports');

        print('💻 Reports saved to macOS home directory');
        print('   Path: ${reportDir.path}');
        print('');

        if (!await reportDir.exists()) {
          await reportDir.create(recursive: true);
        }

        return reportDir;
      }
    } catch (e) {
      print('⚠️  Could not use home directory: $e');
    }

    // Last resort: System temp on macOS
    print('⚠️  Using system temp directory');
    final tempDir = Directory.systemTemp;
    final reportDir = Directory('${tempDir.path}/flutter_test_reports');

    print('   Path: ${reportDir.path}');
    print('');

    return reportDir;
  }

  /// Find workspace root by looking for pubspec.yaml
  Future<Directory?> _findWorkspaceRoot() async {
    try {
      // Start from current directory
      var current = Directory.current;

      // Search up the directory tree for pubspec.yaml
      for (var i = 0; i < 10; i++) {
        final pubspecFile = File('${current.path}/pubspec.yaml');
        if (await pubspecFile.exists()) {
          print('✅ Found workspace root: ${current.path}');
          return current;
        }

        // Go up one level
        final parent = current.parent;
        if (parent.path == current.path) {
          // Reached root, stop
          break;
        }
        current = parent;
      }

      // Try hardcoded path as fallback for your specific workspace
      final hardcodedPath = Directory(
        '/Users/JayprakashPal/Desktop/iltc-dev/iltc-flutter_new',
      );
      if (await hardcodedPath.exists()) {
        final pubspecFile = File('${hardcodedPath.path}/pubspec.yaml');
        if (await pubspecFile.exists()) {
          print('✅ Using known workspace path: ${hardcodedPath.path}');
          return hardcodedPath;
        }
      }

      return null;
    } catch (e) {
      print('Error finding workspace root: $e');
      return null;
    }
  }

  /// Detect if code is running on actual device vs development machine
  /// NOTE: This is kept for reference but not actively used now
  bool _isRunningOnActualDevice() {
    try {
      // Check if current directory path indicates device execution
      final currentDir = Directory.current.path;

      // Android device paths
      if (currentDir.startsWith('/data/') ||
          currentDir.contains('code_cache') ||
          currentDir.contains('app_flutter') ||
          currentDir.contains('/storage/emulated')) {
        return true;
      }

      // iOS device paths
      if (currentDir.contains('/private/var/') ||
          currentDir.contains('Containers/Bundle') ||
          currentDir.contains('Application/')) {
        return true;
      }

      // Check system temp path
      final tempPath = Directory.systemTemp.path;
      if (tempPath.startsWith('/data/') ||
          tempPath.contains('icici.lombard') ||
          tempPath.contains('/var/mobile/')) {
        return true;
      }

      return false;
    } catch (e) {
      // If we can't determine, assume device for safety
      return true;
    }
  }

  /// Generate JSON report
  Future<void> _generateJsonReport(
    String filePath,
    TestResult testResult,
    List<ApiCallData> apiCalls,
    List<ApiTestResult> apiResults,
    DateTime timestamp,
  ) async {
    final report = {
      'testReport': {
        'metadata': {
          'testSuiteName': testResult.suiteName,
          'timestamp': timestamp.toIso8601String(),
          'duration': {
            'milliseconds': testResult.totalDuration.inMilliseconds,
            'seconds': testResult.totalDuration.inSeconds,
            'formatted': _formatDuration(testResult.totalDuration),
          },
          'platform': Platform.operatingSystem,
          'reportVersion': '2.0.0',
        },
        'summary': {
          'status': testResult.status.name,
          'passed': testResult.status == TestStatus.passed,
          'uiSteps': {
            'total': testResult.totalSteps,
            'passed': testResult.passedSteps,
            'failed': testResult.failedSteps,
            'skipped': testResult.skippedSteps,
            'successRate': testResult.successRate,
          },
          'apiTests': {
            'total': apiResults.length,
            'passed': apiResults.where((a) => a.isSuccess).length,
            'failed': apiResults.where((a) => !a.isSuccess).length,
            'successRate': apiResults.isEmpty
                ? 0.0
                : (apiResults.where((a) => a.isSuccess).length /
                      apiResults.length *
                      100),
          },
          'apiCalls': {
            'total': apiCalls.length,
            'successful': apiCalls
                .where(
                  (c) =>
                      (c.statusCode ?? 0) >= 200 && (c.statusCode ?? 0) < 300,
                )
                .length,
            'failed': apiCalls.where((c) => (c.statusCode ?? 0) >= 400).length,
          },
        },
        'phases': {
          'setup': _convertStepResultsToJson(testResult.setupResults),
          'test': _convertStepResultsToJson(testResult.testResults),
          'api': _convertStepResultsToJson(testResult.apiResults),
          'assertions': _convertStepResultsToJson(testResult.assertionResults),
          'cleanup': _convertStepResultsToJson(testResult.cleanupResults),
        },
        'apiTestResults': apiResults.map((r) => r.toJson()).toList(),
        'capturedApiCalls': apiCalls
            .map(
              (c) => {
                'id': c.id,
                'method': c.method,
                'url': c.url,
                'statusCode': c.statusCode,
                'duration': c.duration.inMilliseconds,
                'timestamp': c.timestamp.toIso8601String(),
              },
            )
            .toList(),
        'errors': {
          'mainError': testResult.error,
          'cleanupError': testResult.cleanupError,
          'warnings': testResult.warnings,
        },
        'metadata': testResult.metadata,
      },
    };

    final file = File(filePath);
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(report));
  }

  /// Generate HTML report (beautiful, interactive)
  Future<void> _generateHtmlReport(
    String filePath,
    TestResult testResult,
    List<ApiCallData> apiCalls,
    List<ApiTestResult> apiResults,
    DateTime timestamp,
  ) async {
    final statusIcon = testResult.status == TestStatus.passed ? '✅' : '❌';
    final statusColor = testResult.status == TestStatus.passed
        ? '#10b981'
        : '#ef4444';
    final successRate = testResult.successRate;
    final apiSuccessRate = apiResults.isEmpty
        ? 0.0
        : (apiResults.where((a) => a.isSuccess).length /
              apiResults.length *
              100);

    final html =
        '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Report - ${testResult.suiteName}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header .subtitle { font-size: 1.2em; opacity: 0.9; }
        .status-badge {
            display: inline-block;
            padding: 12px 24px;
            border-radius: 30px;
            font-weight: bold;
            font-size: 1.1em;
            margin-top: 20px;
            background: $statusColor;
        }
        .content { padding: 40px; }
        .summary-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        .card {
            background: linear-gradient(135deg, #f6f8fb 0%, #e9ecef 100%);
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            border-left: 4px solid #667eea;
        }
        .card h3 { color: #667eea; margin-bottom: 15px; font-size: 1.1em; }
        .card .value { font-size: 2.5em; font-weight: bold; color: #333; }
        .card .label { color: #666; font-size: 0.9em; margin-top: 5px; }
        .progress-bar {
            width: 100%;
            height: 12px;
            background: #e9ecef;
            border-radius: 6px;
            overflow: hidden;
            margin-top: 10px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #10b981 0%, #059669 100%);
            transition: width 0.3s ease;
        }
        .section {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 12px;
            margin-bottom: 25px;
        }
        .section h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.5em;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        .step-list { list-style: none; }
        .step-item {
            background: white;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 8px;
            border-left: 4px solid #10b981;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        .step-item.failed { border-left-color: #ef4444; }
        .step-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: bold;
        }
        .step-duration { color: #666; font-size: 0.9em; }
        .api-call {
            background: white;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 8px;
            border-left: 4px solid #3b82f6;
        }
        .api-call .method { 
            display: inline-block;
            padding: 4px 12px;
            border-radius: 4px;
            font-weight: bold;
            font-size: 0.85em;
            margin-right: 10px;
        }
        .method-GET { background: #10b981; color: white; }
        .method-POST { background: #3b82f6; color: white; }
        .method-PUT { background: #f59e0b; color: white; }
        .method-DELETE { background: #ef4444; color: white; }
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }
        .timestamp { color: #999; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$statusIcon Test Report</h1>
            <div class="subtitle">${testResult.suiteName}</div>
            <div class="status-badge">${testResult.status.name.toUpperCase()}</div>
        </div>

        <div class="content">
            <!-- Summary Cards -->
            <div class="summary-cards">
                <div class="card">
                    <h3>Duration</h3>
                    <div class="value">${testResult.totalDuration.inSeconds}s</div>
                    <div class="label">${testResult.totalDuration.inMilliseconds}ms total</div>
                </div>
                <div class="card">
                    <h3>UI Steps</h3>
                    <div class="value">${testResult.passedSteps}/${testResult.totalSteps}</div>
                    <div class="label">Success Rate: ${successRate.toStringAsFixed(1)}%</div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${successRate}%"></div>
                    </div>
                </div>
                <div class="card">
                    <h3>API Tests</h3>
                    <div class="value">${apiResults.where((a) => a.isSuccess).length}/${apiResults.length}</div>
                    <div class="label">Success Rate: ${apiSuccessRate.toStringAsFixed(1)}%</div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${apiSuccessRate}%"></div>
                    </div>
                </div>
                <div class="card">
                    <h3>API Calls</h3>
                    <div class="value">${apiCalls.length}</div>
                    <div class="label">Total captured calls</div>
                </div>
            </div>

            <!-- Test Steps -->
            ${_generateHtmlTestSteps(testResult)}

            <!-- API Test Results -->
            ${_generateHtmlApiResults(apiResults)}

            <!-- Captured API Calls -->
            ${_generateHtmlApiCalls(apiCalls)}
        </div>

        <div class="footer">
            <p>Generated by Flutter Test Pilot on ${timestamp.toLocal()}</p>
            <p class="timestamp">Report Version 2.0.0</p>
        </div>
    </div>
</body>
</html>
''';

    final file = File(filePath);
    await file.writeAsString(html);
  }

  /// Generate Markdown report
  Future<void> _generateMarkdownReport(
    String filePath,
    TestResult testResult,
    List<ApiCallData> apiCalls,
    List<ApiTestResult> apiResults,
    DateTime timestamp,
  ) async {
    final statusIcon = testResult.status == TestStatus.passed ? '✅' : '❌';
    final successRate = testResult.successRate;
    final apiSuccessRate = apiResults.isEmpty
        ? 0.0
        : (apiResults.where((a) => a.isSuccess).length /
              apiResults.length *
              100);

    final markdown =
        '''
# $statusIcon Test Report

**Test Suite:** ${testResult.suiteName}  
**Status:** ${testResult.status.name.toUpperCase()}  
**Timestamp:** ${timestamp.toLocal()}  
**Duration:** ${_formatDuration(testResult.totalDuration)}

---

## 📊 Summary

| Category | Metric | Value |
|----------|--------|-------|
| **Status** | Overall | ${testResult.status.name.toUpperCase()} |
| **Duration** | Total Time | ${testResult.totalDuration.inSeconds}s (${testResult.totalDuration.inMilliseconds}ms) |
| **UI Steps** | Total | ${testResult.totalSteps} |
| **UI Steps** | Passed | ${testResult.passedSteps} (${successRate.toStringAsFixed(1)}%) |
| **UI Steps** | Failed | ${testResult.failedSteps} |
| **UI Steps** | Skipped | ${testResult.skippedSteps} |
| **API Tests** | Total | ${apiResults.length} |
| **API Tests** | Passed | ${apiResults.where((a) => a.isSuccess).length} (${apiSuccessRate.toStringAsFixed(1)}%) |
| **API Tests** | Failed | ${apiResults.where((a) => !a.isSuccess).length} |
| **API Calls** | Total Captured | ${apiCalls.length} |

---

## 📝 Test Execution Details

${_generateMarkdownTestSteps(testResult)}

---

## 🌐 API Test Results

${_generateMarkdownApiResults(apiResults)}

---

## 📡 Captured API Calls

${_generateMarkdownApiCalls(apiCalls)}

---

## ⚠️ Warnings & Errors

${testResult.warnings.isEmpty ? '_No warnings_' : testResult.warnings.map((w) => '- ⚠️  $w').join('\n')}

${testResult.error != null ? '**Error:** ${testResult.error}' : ''}

---

*Generated by Flutter Test Pilot on ${timestamp.toLocal()}*  
*Report Version: 2.0.0*
''';

    final file = File(filePath);
    await file.writeAsString(markdown);
  }

  /// Generate summary text file
  Future<void> _generateSummaryFile(
    String filePath,
    TestResult testResult,
    List<ApiCallData> apiCalls,
    List<ApiTestResult> apiResults,
    DateTime timestamp,
  ) async {
    final statusIcon = testResult.status == TestStatus.passed ? '✅' : '❌';

    final summary =
        '''
═══════════════════════════════════════════════════════════════
$statusIcon LATEST TEST SUMMARY
═══════════════════════════════════════════════════════════════

Test Suite: ${testResult.suiteName}
Status: ${testResult.status.name.toUpperCase()}
Timestamp: ${timestamp.toLocal()}
Duration: ${_formatDuration(testResult.totalDuration)}

───────────────────────────────────────────────────────────────
UI TEST RESULTS
───────────────────────────────────────────────────────────────
Total Steps: ${testResult.totalSteps}
Passed: ${testResult.passedSteps}
Failed: ${testResult.failedSteps}
Skipped: ${testResult.skippedSteps}
Success Rate: ${testResult.successRate.toStringAsFixed(1)}%

───────────────────────────────────────────────────────────────
API TEST RESULTS
───────────────────────────────────────────────────────────────
Total Tests: ${apiResults.length}
Passed: ${apiResults.where((a) => a.isSuccess).length}
Failed: ${apiResults.where((a) => !a.isSuccess).length}
API Calls Captured: ${apiCalls.length}

───────────────────────────────────────────────────────────────
QUICK STATS
───────────────────────────────────────────────────────────────
${testResult.status == TestStatus.passed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}
Overall Duration: ${testResult.totalDuration.inSeconds}s
Warnings: ${testResult.warnings.length}

═══════════════════════════════════════════════════════════════
Generated by Flutter Test Pilot
${timestamp.toLocal()}
═══════════════════════════════════════════════════════════════
''';

    final file = File(filePath);
    await file.writeAsString(summary);
  }

  // Helper methods for HTML generation
  String _generateHtmlTestSteps(TestResult result) {
    if (result.allResults.isEmpty) {
      return '<div class="section"><h2>📝 Test Steps</h2><p>No steps executed</p></div>';
    }

    final stepsHtml = StringBuffer();
    stepsHtml.writeln('<div class="section">');
    stepsHtml.writeln('<h2>📝 Test Execution Steps</h2>');
    stepsHtml.writeln('<ul class="step-list">');

    for (final step in result.allResults) {
      final statusClass = step.success ? '' : 'failed';
      final icon = step.success ? '✅' : '❌';

      stepsHtml.writeln('<li class="step-item $statusClass">');
      stepsHtml.writeln('<div class="step-header">');
      stepsHtml.writeln('<span>$icon ${step.message}</span>');
      stepsHtml.writeln(
        '<span class="step-duration">${step.duration.inMilliseconds}ms</span>',
      );
      stepsHtml.writeln('</div>');
      if (step.error != null) {
        stepsHtml.writeln(
          '<div style="color: #ef4444; margin-top: 8px; font-size: 0.9em;">Error: ${step.error}</div>',
        );
      }
      stepsHtml.writeln('</li>');
    }

    stepsHtml.writeln('</ul>');
    stepsHtml.writeln('</div>');
    return stepsHtml.toString();
  }

  String _generateHtmlApiResults(List<ApiTestResult> apiResults) {
    if (apiResults.isEmpty) {
      return '<div class="section"><h2>🌐 API Test Results</h2><p>No API tests configured</p></div>';
    }

    final html = StringBuffer();
    html.writeln('<div class="section">');
    html.writeln('<h2>🌐 API Test Results</h2>');

    for (final result in apiResults) {
      final icon = result.isSuccess ? '✅' : '❌';
      html.writeln('<div class="api-call">');
      html.writeln(
        '<div style="font-weight: bold; margin-bottom: 10px;">$icon ${result.apiId}</div>',
      );
      html.writeln(
        '<div><span class="method method-${result.apiCall.method}">${result.apiCall.method}</span>${result.apiCall.url}</div>',
      );
      html.writeln(
        '<div style="margin-top: 10px; font-size: 0.9em; color: #666;">',
      );
      html.writeln('Status: ${result.apiCall.statusCode} | ');
      html.writeln('Duration: ${result.apiCall.duration.inMilliseconds}ms | ');
      html.writeln(
        'Validations: ${result.passedValidations}/${result.totalValidations}',
      );
      html.writeln('</div>');

      if (!result.isSuccess && result.failures.isNotEmpty) {
        html.writeln(
          '<div style="margin-top: 10px; color: #ef4444; font-size: 0.9em;">',
        );
        html.writeln('<strong>Failures:</strong>');
        for (final failure in result.failures.take(3)) {
          html.writeln('<div>• ${failure.fieldPath}: ${failure.message}</div>');
        }
        html.writeln('</div>');
      }

      html.writeln('</div>');
    }

    html.writeln('</div>');
    return html.toString();
  }

  String _generateHtmlApiCalls(List<ApiCallData> apiCalls) {
    if (apiCalls.isEmpty) {
      return '<div class="section"><h2>📡 Captured API Calls</h2><p>No API calls captured</p></div>';
    }

    final html = StringBuffer();
    html.writeln('<div class="section">');
    html.writeln('<h2>📡 Captured API Calls</h2>');

    for (final call in apiCalls) {
      html.writeln('<div class="api-call">');
      html.writeln(
        '<div><span class="method method-${call.method}">${call.method}</span>${call.url}</div>',
      );
      html.writeln(
        '<div style="margin-top: 8px; font-size: 0.9em; color: #666;">',
      );
      html.writeln('Status: ${call.statusCode ?? "N/A"} | ');
      html.writeln('Duration: ${call.duration.inMilliseconds}ms');
      html.writeln('</div>');
      html.writeln('</div>');
    }

    html.writeln('</div>');
    return html.toString();
  }

  // Helper methods for Markdown generation
  String _generateMarkdownTestSteps(TestResult result) {
    if (result.allResults.isEmpty) {
      return '_No test steps executed_';
    }

    final buffer = StringBuffer();
    buffer.writeln('### Setup Phase (${result.setupResults.length} steps)');
    buffer.writeln('');
    for (final step in result.setupResults) {
      final icon = step.success ? '✅' : '❌';
      buffer.writeln(
        '- $icon ${step.message} (${step.duration.inMilliseconds}ms)',
      );
      if (step.error != null) {
        buffer.writeln('  - Error: ${step.error}');
      }
    }
    buffer.writeln('');

    buffer.writeln('### Test Phase (${result.testResults.length} steps)');
    buffer.writeln('');
    for (final step in result.testResults) {
      final icon = step.success ? '✅' : '❌';
      buffer.writeln(
        '- $icon ${step.message} (${step.duration.inMilliseconds}ms)',
      );
      if (step.error != null) {
        buffer.writeln('  - Error: ${step.error}');
      }
    }
    buffer.writeln('');

    if (result.assertionResults.isNotEmpty) {
      buffer.writeln(
        '### Assertions (${result.assertionResults.length} checks)',
      );
      buffer.writeln('');
      for (final step in result.assertionResults) {
        final icon = step.success ? '✅' : '❌';
        buffer.writeln(
          '- $icon ${step.message} (${step.duration.inMilliseconds}ms)',
        );
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _generateMarkdownApiResults(List<ApiTestResult> apiResults) {
    if (apiResults.isEmpty) {
      return '_No API tests configured_';
    }

    final buffer = StringBuffer();
    for (final result in apiResults) {
      final icon = result.isSuccess ? '✅' : '❌';
      buffer.writeln('### $icon ${result.apiId}');
      buffer.writeln('');
      buffer.writeln('- **Method:** ${result.apiCall.method}');
      buffer.writeln('- **URL:** ${result.apiCall.url}');
      buffer.writeln('- **Status:** ${result.apiCall.statusCode}');
      buffer.writeln(
        '- **Duration:** ${result.apiCall.duration.inMilliseconds}ms',
      );
      buffer.writeln(
        '- **Validations:** ${result.passedValidations}/${result.totalValidations} passed',
      );

      if (!result.isSuccess && result.failures.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('**Failures:**');
        for (final failure in result.failures) {
          buffer.writeln('- ${failure.fieldPath}: ${failure.message}');
          if (failure.expectedValue != null) {
            buffer.writeln('  - Expected: `${failure.expectedValue}`');
          }
          if (failure.actualValue != null) {
            buffer.writeln('  - Actual: `${failure.actualValue}`');
          }
        }
      }

      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _generateMarkdownApiCalls(List<ApiCallData> apiCalls) {
    if (apiCalls.isEmpty) {
      return '_No API calls captured_';
    }

    final buffer = StringBuffer();
    buffer.writeln('| # | Method | URL | Status | Duration |');
    buffer.writeln('|---|--------|-----|--------|----------|');

    for (var i = 0; i < apiCalls.length; i++) {
      final call = apiCalls[i];
      buffer.writeln(
        '| ${i + 1} | ${call.method} | ${call.url} | ${call.statusCode ?? "N/A"} | ${call.duration.inMilliseconds}ms |',
      );
    }

    return buffer.toString();
  }

  List<Map<String, dynamic>> _convertStepResultsToJson(List<dynamic> steps) {
    return steps
        .map(
          (step) => {
            'success': step.success,
            'message': step.message,
            'duration': step.duration.inMilliseconds,
            'error': step.error,
          },
        )
        .toList();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  void _printPlatformInstructions(
    String reportDir,
    Map<String, String> reports,
  ) {
    if (Platform.isAndroid) {
      print('💡 To view reports on Android device:');
      print('   1. Pull files from device:');
      print('      adb pull $reportDir ./test_reports/');
      print('   2. Open HTML report:');
      print('      open ./test_reports/*.html');
    } else if (Platform.isIOS) {
      print('💡 To view reports on iOS device:');
      print('   Reports saved in: $reportDir');
      print('   Files can be accessed via iOS file sharing or Xcode');
    } else {
      print('💡 To view reports:');
      if (reports.containsKey('HTML Report')) {
        print('   open ${reports["HTML Report"]}');
      }
      print('   Or browse to: $reportDir');
    }
    print('');
  }
}
