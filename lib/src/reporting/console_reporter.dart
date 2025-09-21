// console_reporter.dart - Console output reporter for test results
import 'dart:io';

import '../../flutter_test_pilot.dart';
import '../test_suite/test_result.dart';
import '../test_suite/test_status.dart';
import '../test_suite/step_result.dart';


/// Reporter that outputs test results to console with colored formatting
class ConsoleReporter {
  final bool showDetails;
  final bool showTimings;
  final bool useColors;
  final int indentSize;

  const ConsoleReporter({
    this.showDetails = true,
    this.showTimings = true,
    this.useColors = true,
    this.indentSize = 2,
  });

  /// Report a single test result
  void reportTest(TestResult result) {
    final indent = ' ' * indentSize;
    final status = _getStatusIcon(result.status);
    final duration = result.totalDuration.inMilliseconds;
    
    // Main test line
    print('$status ${result.suiteName}${showTimings ? ' (${duration}ms)' : ''}');

    // Show error if failed
    if (result.status == TestStatus.failed && result.error != null) {
      print('${indent}❌ ${_colorize('Error:', _ConsoleColor.red)} ${result.error}');
    }

    // Show cleanup error if exists
    if (result.cleanupError != null) {
      print('${indent}⚠️  ${_colorize('Cleanup Error:', _ConsoleColor.yellow)} ${result.cleanupError}');
    }

    // Show detailed step results if enabled
    if (showDetails) {
      _reportPhaseResults('Setup', result.setupResults, indent);
      _reportPhaseResults('Test', result.testResults, indent);
      _reportPhaseResults('APIs', result.cleanupResults, indent); // Note: APIs currently stored in cleanup
      _reportPhaseResults('Cleanup', result.cleanupResults, indent);
    }

    print(''); // Empty line for readability
  }

  /// Report multiple test results (for test groups)
  void reportGroup(TestGroup group, List<TestResult> results) {
    final passed = results.where((r) => r.status == TestStatus.passed).length;
    final failed = results.where((r) => r.status == TestStatus.failed).length;
    final skipped = results.where((r) => r.status == TestStatus.skipped).length;
    final totalDuration = results.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.totalDuration,
    );

    // Group header
    print(_colorize('📋 Test Group: ${group.name}', _ConsoleColor.blue));
    if (group.description != null) {
      print('   ${group.description}');
    }
    print('');

    // Individual test results
    for (final result in results) {
      reportTest(result);
    }

    // Group summary
    _printSeparator();
    print(_colorize('📊 Group Summary', _ConsoleColor.blue));
    print('   Group: ${group.name}');
    print('   Total Tests: ${results.length}');
    print('   ✅ Passed: ${_colorize('$passed', _ConsoleColor.green)}');
    print('   ❌ Failed: ${_colorize('$failed', failed > 0 ? _ConsoleColor.red : _ConsoleColor.gray)}');
    print('   ⏭️  Skipped: ${_colorize('$skipped', skipped > 0 ? _ConsoleColor.yellow : _ConsoleColor.gray)}');
    print('   ⏱️  Total Duration: ${totalDuration.inMilliseconds}ms');
    
    // Success rate
    final successRate = results.isEmpty ? 0.0 : (passed / results.length * 100);
    final rateColor = successRate == 100 ? _ConsoleColor.green : 
                     successRate >= 80 ? _ConsoleColor.yellow : _ConsoleColor.red;
    print('   📈 Success Rate: ${_colorize('${successRate.toStringAsFixed(1)}%', rateColor)}');
    
    _printSeparator();
    print('');
  }

  /// Report phase-specific results (setup, test, cleanup)
  void _reportPhaseResults(String phaseName, List<StepResult> results, String baseIndent) {
    if (results.isEmpty) return;

    final phaseIndent = '$baseIndent  ';
    final failedSteps = results.where((r) => !r.success).toList();
    
    if (failedSteps.isNotEmpty || showDetails) {
      print('$baseIndent📝 $phaseName Phase:');
      
      for (int i = 0; i < results.length; i++) {
        final step = results[i];
        final stepIcon = step.success ? '✓' : '✗';
        final stepColor = step.success ? _ConsoleColor.green : _ConsoleColor.red;
        final timing = showTimings ? ' (${step.duration.inMilliseconds}ms)' : '';
        
        print('$phaseIndent${_colorize(stepIcon, stepColor)} Step ${i + 1}$timing');
        
        if (step.message != null) {
          print('$phaseIndent  💬 ${step.message}');
        }
        
        if (!step.success && step.error != null) {
          print('$phaseIndent  ❌ ${_colorize('Error:', _ConsoleColor.red)} ${step.error}');
        }
        
        if (step.data != null && step.data!.isNotEmpty) {
          print('$phaseIndent  📊 Data: ${step.data}');
        }
      }
    }
  }

  /// Get status icon for test result
  String _getStatusIcon(TestStatus status) {
    switch (status) {
      case TestStatus.passed:
        return _colorize('✅', _ConsoleColor.green);
      case TestStatus.failed:
        return _colorize('❌', _ConsoleColor.red);
      case TestStatus.running:
        return _colorize('🔄', _ConsoleColor.yellow);
      case TestStatus.skipped:
        return _colorize('⏭️', _ConsoleColor.yellow);
    }
  }

  /// Print a separator line
  void _printSeparator() {
    print(_colorize('${'─' * 60}', _ConsoleColor.gray));
  }

  /// Apply color to text if colors are enabled
  String _colorize(String text, _ConsoleColor color) {
    if (!useColors || !stdout.supportsAnsiEscapes) {
      return text;
    }
    
    return '${color._ansiCode}$text${_ConsoleColor.reset._ansiCode}';
  }

  /// Print test execution summary with statistics
  static void printExecutionSummary(List<TestResult> allResults) {
    if (allResults.isEmpty) {
      print('No tests were executed.');
      return;
    }

    final reporter = ConsoleReporter();
    reporter._printSeparator();
    print(reporter._colorize('🎯 Test Execution Summary', _ConsoleColor.blue));
    reporter._printSeparator();

    final passed = allResults.where((r) => r.status == TestStatus.passed).length;
    final failed = allResults.where((r) => r.status == TestStatus.failed).length;
    final skipped = allResults.where((r) => r.status == TestStatus.skipped).length;
    final totalDuration = allResults.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.totalDuration,
    );
    final avgDuration = Duration(milliseconds: totalDuration.inMilliseconds ~/ allResults.length);

    print('Total Tests: ${allResults.length}');
    print('✅ Passed: ${reporter._colorize('$passed', _ConsoleColor.green)}');
    print('❌ Failed: ${reporter._colorize('$failed', failed > 0 ? _ConsoleColor.red : _ConsoleColor.gray)}');
    print('⏭️  Skipped: ${reporter._colorize('$skipped', skipped > 0 ? _ConsoleColor.yellow : _ConsoleColor.gray)}');
    print('⏱️  Total Duration: ${totalDuration.inSeconds}.${(totalDuration.inMilliseconds % 1000).toString().padLeft(3, '0')}s');
    print('📊 Average Duration: ${avgDuration.inMilliseconds}ms per test');

    final successRate = passed / allResults.length * 100;
    final rateColor = successRate == 100 ? _ConsoleColor.green : 
                     successRate >= 80 ? _ConsoleColor.yellow : _ConsoleColor.red;
    print('📈 Success Rate: ${reporter._colorize('${successRate.toStringAsFixed(1)}%', rateColor)}');

    // Show failed tests if any
    if (failed > 0) {
      print('\n❌ Failed Tests:');
      final failedResults = allResults.where((r) => r.status == TestStatus.failed);
      for (final result in failedResults) {
        print('   • ${result.suiteName}: ${result.error ?? 'Unknown error'}');
      }
    }

    reporter._printSeparator();
  }
}

/// Console colors for formatted output
enum _ConsoleColor {
  red('\x1B[31m'),
  green('\x1B[32m'),
  yellow('\x1B[33m'),
  blue('\x1B[34m'),
  gray('\x1B[90m'),
  reset('\x1B[0m');

  const _ConsoleColor(this._ansiCode);
  final String _ansiCode;
}