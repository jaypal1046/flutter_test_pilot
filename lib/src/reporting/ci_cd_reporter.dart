// ci_cd_reporter.dart - CI/CD integration reporter
import 'dart:io';
import '../test_suite/test_result.dart';
import '../test_suite/test_status.dart';
import 'json_reporter.dart';

/// Reporter specifically designed for CI/CD integration
/// Supports: GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure Pipelines
class CICDReporter {
  final String? outputDir;
  final bool generateJUnit;
  final bool generateJSON;
  final bool generateHTML;
  final CIPlatform? platform;

  CICDReporter({
    this.outputDir = 'test-results',
    this.generateJUnit = true,
    this.generateJSON = true,
    this.generateHTML = true,
    CIPlatform? platform,
  }) : platform = platform ?? _detectCIPlatform();

  /// Detect CI platform from environment variables
  static CIPlatform? _detectCIPlatform() {
    if (Platform.environment.containsKey('GITHUB_ACTIONS')) {
      return CIPlatform.githubActions;
    } else if (Platform.environment.containsKey('GITLAB_CI')) {
      return CIPlatform.gitlabCI;
    } else if (Platform.environment.containsKey('JENKINS_HOME')) {
      return CIPlatform.jenkins;
    } else if (Platform.environment.containsKey('CIRCLECI')) {
      return CIPlatform.circleCI;
    } else if (Platform.environment.containsKey('AZURE_PIPELINES')) {
      return CIPlatform.azurePipelines;
    } else if (Platform.environment.containsKey('BITBUCKET_BUILD_NUMBER')) {
      return CIPlatform.bitbucket;
    }
    return null;
  }

  /// Generate all reports for CI/CD
  Future<void> generateReports(
    List<TestResult> results, {
    String? suiteName,
    Map<String, dynamic>? metadata,
  }) async {
    final dir = Directory(outputDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final baseName = suiteName ?? 'test-execution-$timestamp';

    // Generate JUnit XML (most CI/CD platforms support this)
    if (generateJUnit) {
      await _generateJUnitReport(results, '$outputDir/$baseName-junit.xml');
    }

    // Generate JSON report
    if (generateJSON) {
      await _generateJSONReport(
        results,
        '$outputDir/$baseName-report.json',
        metadata,
      );
    }

    // Generate HTML report
    if (generateHTML) {
      await _generateHTMLReport(results, '$outputDir/$baseName-report.html');
    }

    // Generate platform-specific annotations
    _generatePlatformAnnotations(results);

    // Print summary
    _printCISummary(results);
  }

  /// Generate JUnit XML report
  Future<void> _generateJUnitReport(
    List<TestResult> results,
    String path,
  ) async {
    final reporter = JsonReporter();
    final xml = reporter.generateJUnitXml(results);
    final file = File(path);
    await file.writeAsString(xml);
    print('📄 JUnit XML report: $path');
  }

  /// Generate JSON report
  Future<void> _generateJSONReport(
    List<TestResult> results,
    String path,
    Map<String, dynamic>? metadata,
  ) async {
    final reporter = JsonReporter(outputFile: path);
    final report = reporter.generateExecutionReport(
      results,
      environment: _getEnvironmentInfo(),
      configuration: metadata,
    );
    await reporter.outputReport(report);
  }

  /// Generate HTML report
  Future<void> _generateHTMLReport(
    List<TestResult> results,
    String path,
  ) async {
    final html = _buildHTMLReport(results);
    final file = File(path);
    await file.writeAsString(html);
    print('📄 HTML report: $path');
  }

  /// Build HTML report content
  String _buildHTMLReport(List<TestResult> results) {
    final passed = results.where((r) => r.status == TestStatus.passed).length;
    final failed = results.where((r) => r.status == TestStatus.failed).length;
    final successRate = results.isEmpty ? 0.0 : (passed / results.length * 100);
    final totalDuration = results.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.totalDuration,
    );

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flutter Test Pilot - Test Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .header h1 { font-size: 28px; margin-bottom: 10px; }
        .header .meta { opacity: 0.9; font-size: 14px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 30px; border-bottom: 1px solid #e0e0e0; }
        .stat { text-align: center; }
        .stat-value { font-size: 36px; font-weight: bold; margin-bottom: 5px; }
        .stat-label { color: #666; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px; }
        .passed { color: #10b981; }
        .failed { color: #ef4444; }
        .rate { color: #667eea; }
        .duration { color: #f59e0b; }
        .tests { padding: 30px; }
        .test-item { border: 1px solid #e0e0e0; border-radius: 6px; padding: 20px; margin-bottom: 15px; transition: box-shadow 0.2s; }
        .test-item:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .test-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        .test-name { font-size: 18px; font-weight: 600; }
        .test-status { padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; text-transform: uppercase; }
        .status-passed { background: #d1fae5; color: #065f46; }
        .status-failed { background: #fee2e2; color: #991b1b; }
        .test-meta { color: #666; font-size: 14px; margin-top: 8px; }
        .error { background: #fef2f2; border-left: 3px solid #ef4444; padding: 12px; margin-top: 10px; border-radius: 4px; font-family: monospace; font-size: 13px; color: #991b1b; }
        .footer { padding: 20px 30px; background: #f9fafb; border-radius: 0 0 8px 8px; text-align: center; color: #666; font-size: 14px; }
        .progress-bar { height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; margin-top: 10px; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #10b981, #059669); transition: width 0.3s; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Flutter Test Pilot Report</h1>
            <div class="meta">Generated: ${DateTime.now()}</div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${successRate.toStringAsFixed(1)}%"></div>
            </div>
        </div>
        
        <div class="summary">
            <div class="stat">
                <div class="stat-value">${results.length}</div>
                <div class="stat-label">Total Tests</div>
            </div>
            <div class="stat">
                <div class="stat-value passed">$passed</div>
                <div class="stat-label">Passed</div>
            </div>
            <div class="stat">
                <div class="stat-value failed">$failed</div>
                <div class="stat-label">Failed</div>
            </div>
            <div class="stat">
                <div class="stat-value rate">${successRate.toStringAsFixed(1)}%</div>
                <div class="stat-label">Success Rate</div>
            </div>
            <div class="stat">
                <div class="stat-value duration">${totalDuration.inSeconds}s</div>
                <div class="stat-label">Duration</div>
            </div>
        </div>
        
        <div class="tests">
            <h2 style="margin-bottom: 20px;">Test Results</h2>
            ${results.map((r) => _buildTestItemHTML(r)).join('\n')}
        </div>
        
        <div class="footer">
            <strong>Flutter Test Pilot</strong> - Comprehensive Flutter Testing Framework<br>
            Platform: ${platform?.name ?? 'Local'} | Environment: ${_getEnvironmentInfo()['os']}
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildTestItemHTML(TestResult result) {
    final isPassed = result.status == TestStatus.passed;
    return '''
<div class="test-item">
    <div class="test-header">
        <div class="test-name">${result.suiteName}</div>
        <div class="test-status ${isPassed ? 'status-passed' : 'status-failed'}">
            ${isPassed ? '✓ Passed' : '✗ Failed'}
        </div>
    </div>
    <div class="test-meta">
        Duration: ${result.totalDuration.inMilliseconds}ms | 
        Steps: ${result.setupResults.length + result.testResults.length + result.cleanupResults.length}
    </div>
    ${result.error != null ? '<div class="error">Error: ${_escapeHtml(result.error!)}</div>' : ''}
</div>
''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Generate platform-specific annotations
  void _generatePlatformAnnotations(List<TestResult> results) {
    if (platform == null) return;

    for (final result in results) {
      if (result.status == TestStatus.failed) {
        switch (platform!) {
          case CIPlatform.githubActions:
            _printGitHubAnnotation(result);
            break;
          case CIPlatform.gitlabCI:
            _printGitLabAnnotation(result);
            break;
          case CIPlatform.azurePipelines:
            _printAzureAnnotation(result);
            break;
          default:
            break;
        }
      }
    }
  }

  void _printGitHubAnnotation(TestResult result) {
    print(
      '::error title=Test Failed::${result.suiteName} - ${result.error ?? "Unknown error"}',
    );
  }

  void _printGitLabAnnotation(TestResult result) {
    // GitLab doesn't have special annotation format, but we can use colored output
    print('\x1B[31m[FAIL]\x1B[0m ${result.suiteName}: ${result.error}');
  }

  void _printAzureAnnotation(TestResult result) {
    print(
      '##vso[task.logissue type=error]${result.suiteName}: ${result.error}',
    );
  }

  /// Print CI summary
  void _printCISummary(List<TestResult> results) {
    final passed = results.where((r) => r.status == TestStatus.passed).length;
    final failed = results.where((r) => r.status == TestStatus.failed).length;

    print('\n' + '=' * 60);
    print('CI/CD Test Execution Summary');
    print('=' * 60);
    print('Platform: ${platform?.name ?? 'Local'}');
    print('Total Tests: ${results.length}');
    print('✓ Passed: $passed');
    print('✗ Failed: $failed');
    print(
      'Success Rate: ${results.isEmpty ? 0 : (passed / results.length * 100).toStringAsFixed(1)}%',
    );
    print('Reports Directory: $outputDir');
    print('=' * 60 + '\n');
  }

  /// Get environment information
  Map<String, dynamic> _getEnvironmentInfo() {
    return {
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'dart': Platform.version,
      'ciPlatform': platform?.name,
      'environment': {
        'CI': Platform.environment['CI'],
        'BUILD_NUMBER':
            Platform.environment['BUILD_NUMBER'] ??
            Platform.environment['GITHUB_RUN_NUMBER'] ??
            Platform.environment['CI_PIPELINE_ID'],
        'BRANCH':
            Platform.environment['BRANCH_NAME'] ??
            Platform.environment['GITHUB_REF'] ??
            Platform.environment['CI_COMMIT_BRANCH'],
        'COMMIT':
            Platform.environment['GIT_COMMIT'] ??
            Platform.environment['GITHUB_SHA'] ??
            Platform.environment['CI_COMMIT_SHA'],
      },
    };
  }

  /// Get appropriate exit code for CI/CD
  int getExitCode(List<TestResult> results) {
    final failed = results.where((r) => r.status == TestStatus.failed).length;
    return failed > 0 ? 1 : 0;
  }
}

/// Supported CI/CD platforms
enum CIPlatform {
  githubActions,
  gitlabCI,
  jenkins,
  circleCI,
  azurePipelines,
  bitbucket,
}
