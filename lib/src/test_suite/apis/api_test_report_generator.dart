import 'dart:io';
import 'dart:convert';
import 'model/api_call_data.dart';
import 'model/api_test_result.dart';

/// Generates comprehensive API test reports in multiple formats
class ApiTestReportGenerator {
  /// Generate all report formats and return file paths
  Future<Map<String, String>> generateReports({
    required String testSuiteName,
    required List<ApiTestResult> apiResults,
    required List<ApiCallData> capturedCalls,
    required Duration testDuration,
    required DateTime timestamp,
    String? outputDir,
  }) async {
    final reportDir = outputDir ?? await _getReportDirectory();
    final dateStr = timestamp
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')[0];
    final safeTestName = testSuiteName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');

    final reports = <String, String>{};

    // Generate JSON report
    final jsonPath = '$reportDir/api_test_report_${safeTestName}_$dateStr.json';
    await _generateJsonReport(
      jsonPath,
      testSuiteName,
      apiResults,
      capturedCalls,
      testDuration,
      timestamp,
    );
    reports['JSON Report'] = jsonPath;

    // Generate HTML report
    final htmlPath = '$reportDir/api_test_report_${safeTestName}_$dateStr.html';
    await _generateHtmlReport(
      htmlPath,
      testSuiteName,
      apiResults,
      capturedCalls,
      testDuration,
      timestamp,
    );
    reports['HTML Report'] = htmlPath;

    // Generate Markdown report
    final mdPath = '$reportDir/api_test_report_${safeTestName}_$dateStr.md';
    await _generateMarkdownReport(
      mdPath,
      testSuiteName,
      apiResults,
      capturedCalls,
      testDuration,
      timestamp,
    );
    reports['Markdown Report'] = mdPath;

    return reports;
  }

  /// Get or create report directory
  Future<String> _getReportDirectory() async {
    // Use the integration_test directory which is guaranteed to be writable
    final dir = Directory('integration_test/test_reports/api_tests');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Generate JSON report
  Future<void> _generateJsonReport(
    String filePath,
    String testSuiteName,
    List<ApiTestResult> apiResults,
    List<ApiCallData> capturedCalls,
    Duration testDuration,
    DateTime timestamp,
  ) async {
    final report = {
      'testSuiteName': testSuiteName,
      'timestamp': timestamp.toIso8601String(),
      'duration': testDuration.inMilliseconds,
      'summary': {
        'totalTests': apiResults.length,
        'passed': apiResults.where((r) => r.isSuccess).length,
        'failed': apiResults.where((r) => !r.isSuccess).length,
        'totalApiCalls': capturedCalls.length,
      },
      'apiResults': apiResults.map((r) => r.toJson()).toList(),
      'capturedCalls': capturedCalls
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
    };

    final file = File(filePath);
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(report));
  }

  /// Generate HTML report
  Future<void> _generateHtmlReport(
    String filePath,
    String testSuiteName,
    List<ApiTestResult> apiResults,
    List<ApiCallData> capturedCalls,
    Duration testDuration,
    DateTime timestamp,
  ) async {
    final passedCount = apiResults.where((r) => r.isSuccess).length;
    final failedCount = apiResults.where((r) => !r.isSuccess).length;
    final successRate = apiResults.isEmpty
        ? 0
        : (passedCount / apiResults.length * 100);

    final html =
        '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Test Report - $testSuiteName</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
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
        .header h1 { font-size: 32px; margin-bottom: 10px; }
        .header p { opacity: 0.9; font-size: 14px; }
        .summary { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f7fafc;
        }
        .summary-card { 
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
        }
        .summary-card h3 { 
            font-size: 14px;
            color: #718096;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .summary-card .value { 
            font-size: 36px;
            font-weight: bold;
            color: #2d3748;
        }
        .summary-card.success .value { color: #48bb78; }
        .summary-card.error .value { color: #f56565; }
        .summary-card.duration .value { font-size: 28px; }
        .progress-bar {
            height: 8px;
            background: #e2e8f0;
            border-radius: 4px;
            overflow: hidden;
            margin-top: 10px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #48bb78 0%, #38a169 100%);
            transition: width 0.3s ease;
        }
        .content { padding: 30px; }
        .section { margin-bottom: 40px; }
        .section h2 { 
            font-size: 24px;
            margin-bottom: 20px;
            color: #2d3748;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }
        .test-result { 
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 15px;
            transition: all 0.3s ease;
        }
        .test-result:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }
        .test-result.passed { border-left: 4px solid #48bb78; }
        .test-result.failed { border-left: 4px solid #f56565; }
        .test-header { 
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        .test-title { 
            font-size: 18px;
            font-weight: 600;
            color: #2d3748;
        }
        .badge { 
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge.success { background: #c6f6d5; color: #22543d; }
        .badge.error { background: #fed7d7; color: #742a2a; }
        .test-details { 
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
            padding: 15px;
            background: #f7fafc;
            border-radius: 6px;
        }
        .detail-item { 
            font-size: 13px;
        }
        .detail-label { 
            color: #718096;
            font-weight: 500;
            margin-bottom: 5px;
        }
        .detail-value { 
            color: #2d3748;
            font-family: 'Courier New', monospace;
        }
        .failures { 
            margin-top: 15px;
            background: #fff5f5;
            border: 1px solid #feb2b2;
            border-radius: 6px;
            padding: 15px;
        }
        .failures h4 { 
            color: #c53030;
            margin-bottom: 10px;
            font-size: 14px;
        }
        .failure-item { 
            padding: 10px;
            background: white;
            border-left: 3px solid #f56565;
            margin-bottom: 10px;
            border-radius: 4px;
        }
        .failure-item:last-child { margin-bottom: 0; }
        .failure-path { 
            font-weight: 600;
            color: #742a2a;
            margin-bottom: 5px;
        }
        .failure-message { 
            color: #c53030;
            font-size: 13px;
            margin-bottom: 5px;
        }
        .failure-expected, .failure-actual { 
            font-size: 12px;
            color: #718096;
            font-family: 'Courier New', monospace;
        }
        .api-calls { 
            margin-top: 30px;
        }
        .api-call { 
            background: #f7fafc;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 10px;
            font-size: 13px;
        }
        .api-call-header { 
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 10px;
        }
        .method { 
            display: inline-block;
            padding: 3px 8px;
            border-radius: 4px;
            font-weight: 600;
            font-size: 11px;
        }
        .method.POST { background: #c3dafe; color: #2c5282; }
        .method.GET { background: #c6f6d5; color: #22543d; }
        .method.PUT { background: #feebc8; color: #7c2d12; }
        .method.DELETE { background: #fed7d7; color: #742a2a; }
        .url { 
            color: #4a5568;
            font-family: 'Courier New', monospace;
            flex: 1;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .status-code { 
            padding: 3px 8px;
            border-radius: 4px;
            font-weight: 600;
            font-size: 11px;
        }
        .status-code.success { background: #c6f6d5; color: #22543d; }
        .status-code.error { background: #fed7d7; color: #742a2a; }
        .footer { 
            text-align: center;
            padding: 20px;
            background: #f7fafc;
            color: #718096;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📡 API Test Report</h1>
            <p>$testSuiteName</p>
            <p>${timestamp.toLocal()}</p>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Total Tests</h3>
                <div class="value">${apiResults.length}</div>
            </div>
            <div class="summary-card success">
                <h3>Passed</h3>
                <div class="value">$passedCount</div>
            </div>
            <div class="summary-card error">
                <h3>Failed</h3>
                <div class="value">$failedCount</div>
            </div>
            <div class="summary-card duration">
                <h3>Duration</h3>
                <div class="value">${testDuration.inSeconds}s</div>
            </div>
            <div class="summary-card" style="grid-column: span 2;">
                <h3>Success Rate</h3>
                <div class="value">${successRate.toStringAsFixed(1)}%</div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${successRate}%"></div>
                </div>
            </div>
        </div>
        
        <div class="content">
            <div class="section">
                <h2>📝 Test Results</h2>
                ${_generateHtmlTestResults(apiResults)}
            </div>
            
            <div class="section api-calls">
                <h2>🌐 Captured API Calls</h2>
                ${_generateHtmlApiCalls(capturedCalls)}
            </div>
        </div>
        
        <div class="footer">
            <p>Generated by Flutter Test Pilot • ${timestamp.toLocal()}</p>
            <p>Total API calls: ${capturedCalls.length} • Test duration: ${testDuration.inSeconds}s</p>
        </div>
    </div>
</body>
</html>
''';

    final file = File(filePath);
    await file.writeAsString(html);
  }

  String _generateHtmlTestResults(List<ApiTestResult> results) {
    if (results.isEmpty) {
      return '<p style="color: #718096;">No API test results to display.</p>';
    }

    return results
        .map((result) {
          final statusClass = result.isSuccess ? 'passed' : 'failed';
          final badgeClass = result.isSuccess ? 'success' : 'error';
          final badgeText = result.isSuccess ? '✅ PASSED' : '❌ FAILED';

          final failuresHtml = !result.isSuccess && result.failures.isNotEmpty
              ? '''
        <div class="failures">
          <h4>⚠️ Validation Failures (${result.failures.length})</h4>
          ${result.failures.map((f) => '''
            <div class="failure-item">
              <div class="failure-path">${f.fieldPath}</div>
              <div class="failure-message">${f.message}</div>
              ${f.expectedValue != null ? '<div class="failure-expected">Expected: ${f.expectedValue}</div>' : ''}
              ${f.actualValue != null ? '<div class="failure-actual">Actual: ${f.actualValue}</div>' : ''}
            </div>
          ''').join('')}
        </div>
      '''
              : '';

          return '''
        <div class="test-result $statusClass">
          <div class="test-header">
            <div class="test-title">${result.apiId}</div>
            <span class="badge $badgeClass">$badgeText</span>
          </div>
          <div class="test-details">
            <div class="detail-item">
              <div class="detail-label">Method</div>
              <div class="detail-value">${result.apiCall.method}</div>
            </div>
            <div class="detail-item">
              <div class="detail-label">URL</div>
              <div class="detail-value" title="${result.apiCall.url}">${_truncateUrl(result.apiCall.url)}</div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Status Code</div>
              <div class="detail-value">${result.apiCall.statusCode ?? 'N/A'}</div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Duration</div>
              <div class="detail-value">${result.apiCall.duration.inMilliseconds}ms</div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Validations</div>
              <div class="detail-value">${result.passedValidations}/${result.totalValidations}</div>
            </div>
          </div>
          $failuresHtml
        </div>
      ''';
        })
        .join('');
  }

  String _generateHtmlApiCalls(List<ApiCallData> calls) {
    if (calls.isEmpty) {
      return '<p style="color: #718096;">No API calls captured.</p>';
    }

    return calls
        .map((call) {
          final statusClass =
              (call.statusCode ?? 0) >= 200 && (call.statusCode ?? 0) < 300
              ? 'success'
              : 'error';

          return '''
        <div class="api-call">
          <div class="api-call-header">
            <span class="method ${call.method}">${call.method}</span>
            <span class="url" title="${call.url}">${call.url}</span>
            <span class="status-code $statusClass">${call.statusCode ?? 'N/A'}</span>
          </div>
          <div style="color: #718096; font-size: 12px;">
            Duration: ${call.duration.inMilliseconds}ms • ${call.timestamp.toLocal()}
          </div>
        </div>
      ''';
        })
        .join('');
  }

  /// Generate Markdown report
  Future<void> _generateMarkdownReport(
    String filePath,
    String testSuiteName,
    List<ApiTestResult> apiResults,
    List<ApiCallData> capturedCalls,
    Duration testDuration,
    DateTime timestamp,
  ) async {
    final passedCount = apiResults.where((r) => r.isSuccess).length;
    final failedCount = apiResults.where((r) => !r.isSuccess).length;
    final successRate = apiResults.isEmpty
        ? 0
        : (passedCount / apiResults.length * 100);

    final markdown =
        '''
# 📡 API Test Report

**Test Suite:** $testSuiteName  
**Timestamp:** ${timestamp.toLocal()}  
**Duration:** ${testDuration.inSeconds}s

---

## 📊 Summary

| Metric | Value |
|--------|-------|
| Total Tests | ${apiResults.length} |
| ✅ Passed | $passedCount |
| ❌ Failed | $failedCount |
| Success Rate | ${successRate.toStringAsFixed(1)}% |
| Total API Calls | ${capturedCalls.length} |

---

## 📝 Test Results

${_generateMarkdownTestResults(apiResults)}

---

## 🌐 Captured API Calls

${_generateMarkdownApiCalls(capturedCalls)}

---

*Generated by Flutter Test Pilot on ${timestamp.toLocal()}*
''';

    final file = File(filePath);
    await file.writeAsString(markdown);
  }

  String _generateMarkdownTestResults(List<ApiTestResult> results) {
    if (results.isEmpty) return '_No test results to display._';

    return results
        .map((result) {
          final icon = result.isSuccess ? '✅' : '❌';
          final status = result.isSuccess ? 'PASSED' : 'FAILED';

          final failureSection = !result.isSuccess && result.failures.isNotEmpty
              ? '''

**⚠️ Validation Failures:**

${result.failures.map((f) => '''
- **${f.fieldPath}**
  - Message: ${f.message}
  ${f.expectedValue != null ? '- Expected: `${f.expectedValue}`' : ''}
  ${f.actualValue != null ? '- Actual: `${f.actualValue}`' : ''}
''').join('\n')}
'''
              : '';

          return '''
### $icon ${result.apiId}

**Status:** $status  
**Method:** ${result.apiCall.method}  
**URL:** `${result.apiCall.url}`  
**Status Code:** ${result.apiCall.statusCode ?? 'N/A'}  
**Duration:** ${result.apiCall.duration.inMilliseconds}ms  
**Validations:** ${result.passedValidations}/${result.totalValidations} passed
$failureSection
''';
        })
        .join('\n---\n\n');
  }

  String _generateMarkdownApiCalls(List<ApiCallData> calls) {
    if (calls.isEmpty) return '_No API calls captured._';

    return '''
| Method | URL | Status | Duration |
|--------|-----|--------|----------|
${calls.map((call) {
      final icon = (call.statusCode ?? 0) >= 200 && (call.statusCode ?? 0) < 300 ? '✅' : '❌';
      return '| ${call.method} | `${_truncateUrl(call.url, 50)}` | $icon ${call.statusCode ?? 'N/A'} | ${call.duration.inMilliseconds}ms |';
    }).join('\n')}
''';
  }

  String _truncateUrl(String url, [int maxLength = 60]) {
    if (url.length <= maxLength) return url;
    final start = url.substring(0, maxLength ~/ 2);
    final end = url.substring(url.length - maxLength ~/ 2);
    return '$start...$end';
  }
}
