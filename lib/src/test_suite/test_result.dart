import 'step_result.dart';
import 'test_status.dart';

enum TestPhase { setup, test, apis, cleanup, assertion }

/// Overall test result with comprehensive tracking
class TestResult {
  final String suiteName;
  TestStatus status = TestStatus.running;
  String? error;
  String? cleanupError;
  final List<StepResult> setupResults = [];
  final List<StepResult> testResults = [];
  final List<StepResult> apiResults = [];
  final List<StepResult> assertionResults = [];
  final List<StepResult> cleanupResults = [];
  final DateTime startTime = DateTime.now();
  DateTime? endTime;

  // Enhanced tracking
  int totalSteps = 0;
  int passedSteps = 0;
  int failedSteps = 0;
  int skippedSteps = 0;
  final List<String> warnings = [];
  final Map<String, dynamic> metadata = {};

  TestResult({required this.suiteName});

  void addStepResult(TestPhase phase, StepResult result) {
    totalSteps++;

    if (result.success) {
      passedSteps++;
    } else {
      failedSteps++;
    }

    switch (phase) {
      case TestPhase.setup:
        setupResults.add(result);
        break;
      case TestPhase.test:
        testResults.add(result);
        break;
      case TestPhase.apis:
        apiResults.add(result);
        break;
      case TestPhase.assertion:
        assertionResults.add(result);
        break;
      case TestPhase.cleanup:
        cleanupResults.add(result);
        break;
    }
  }

  void addWarning(String warning) {
    warnings.add(warning);
  }

  void skipStep() {
    totalSteps++;
    skippedSteps++;
  }

  Duration get totalDuration =>
      (endTime ?? DateTime.now()).difference(startTime);

  double get successRate =>
      totalSteps > 0 ? (passedSteps / totalSteps) * 100 : 0;

  bool get hasPassed => status == TestStatus.passed;
  bool get hasFailed => status == TestStatus.failed;
  bool get hasWarnings => warnings.isNotEmpty;

  List<StepResult> get allResults => [
    ...setupResults,
    ...testResults,
    ...apiResults,
    ...assertionResults,
    ...cleanupResults,
  ];

  String getSummary() {
    return '''
Test Suite: $suiteName
Status: $status
Duration: ${totalDuration.inMilliseconds}ms
Steps: $totalSteps (✅ $passedSteps | ❌ $failedSteps | ⊘ $skippedSteps)
Success Rate: ${successRate.toStringAsFixed(1)}%
${warnings.isNotEmpty ? 'Warnings: ${warnings.length}' : ''}
${error != null ? 'Error: $error' : ''}
''';
  }
}
