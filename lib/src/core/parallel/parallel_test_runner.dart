import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

class ParallelTestRunner {
  final int maxConcurrency;
  final String projectPath;
  final List<String> testFiles;
  final bool verbose;

  ParallelTestRunner({
    required this.maxConcurrency,
    required this.projectPath,
    required this.testFiles,
    this.verbose = false,
  });

  Future<ParallelTestResult> runTests() async {
    final startTime = DateTime.now();
    final results = <TestFileResult>[];
    final queue = List<String>.from(testFiles);
    final activeTests = <Future<TestFileResult>>[];

    print(
      '\n🚀 Running ${testFiles.length} tests with $maxConcurrency workers...\n',
    );

    while (queue.isNotEmpty || activeTests.isNotEmpty) {
      // Start new tests up to maxConcurrency
      while (activeTests.length < maxConcurrency && queue.isNotEmpty) {
        final testFile = queue.removeAt(0);
        final future = _runSingleTest(
          testFile,
          results.length + activeTests.length + 1,
        );
        activeTests.add(future);
      }

      // Wait for at least one test to complete
      if (activeTests.isNotEmpty) {
        final completed = await Future.any(
          activeTests.map((f) => f.then((r) => r)),
        );
        activeTests.removeWhere((f) => f.isCompleted);
        results.add(completed);

        // Print progress
        final progress = results.length;
        final total = testFiles.length;
        final percentage = (progress / total * 100).toStringAsFixed(1);
        print(
          '[$progress/$total] ($percentage%) ${completed.testFile} - ${completed.passed ? '✅ PASSED' : '❌ FAILED'}',
        );
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    return ParallelTestResult(
      results: results,
      totalDuration: duration,
      totalTests: testFiles.length,
    );
  }

  Future<TestFileResult> _runSingleTest(String testFile, int index) async {
    final startTime = DateTime.now();

    try {
      final result = await Process.run('flutter', [
        'test',
        testFile,
        '--no-pub',
      ], workingDirectory: projectPath);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      final passed = result.exitCode == 0;
      final output = result.stdout.toString() + result.stderr.toString();

      return TestFileResult(
        testFile: testFile,
        passed: passed,
        duration: duration,
        output: output,
        exitCode: result.exitCode,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      return TestFileResult(
        testFile: testFile,
        passed: false,
        duration: duration,
        output: 'Error running test: $e',
        exitCode: -1,
      );
    }
  }
}

class ParallelTestResult {
  final List<TestFileResult> results;
  final Duration totalDuration;
  final int totalTests;

  ParallelTestResult({
    required this.results,
    required this.totalDuration,
    required this.totalTests,
  });

  int get passedCount => results.where((r) => r.passed).length;
  int get failedCount => results.where((r) => !r.passed).length;

  void printSummary() {
    print('\n' + '=' * 60);
    print('📊 Test Results Summary');
    print('=' * 60);
    print('Total Tests: $totalTests');
    print('✅ Passed: $passedCount');
    print('❌ Failed: $failedCount');
    print('⏱️  Total Duration: ${totalDuration.inSeconds}s');
    print('=' * 60 + '\n');

    if (failedCount > 0) {
      print('❌ Failed Tests:');
      for (final result in results.where((r) => !r.passed)) {
        print('  - ${result.testFile}');
      }
      print('');
    }
  }
}

class TestFileResult {
  final String testFile;
  final bool passed;
  final Duration duration;
  final String output;
  final int exitCode;

  TestFileResult({
    required this.testFile,
    required this.passed,
    required this.duration,
    required this.output,
    required this.exitCode,
  });
}

extension FutureExtension<T> on Future<T> {
  bool get isCompleted {
    bool completed = false;
    then((_) => completed = true).catchError((_) => completed = true);
    return completed;
  }
}
