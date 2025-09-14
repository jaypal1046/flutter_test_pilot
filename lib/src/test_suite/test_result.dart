import 'step_result.dart';
import 'test_status.dart';

/// Overall test result
class TestResult {
  final String suiteName;
  TestStatus status = TestStatus.running;
  String? error;
  String? cleanupError;
  final List<StepResult> setupResults = [];
  final List<StepResult> testResults = [];
  final List<StepResult> cleanupResults = [];
  final DateTime startTime = DateTime.now();
  DateTime? endTime;

  TestResult({required this.suiteName});

  void addStepResult(String phase, StepResult result) {
    switch (phase) {
      case 'setup':
        setupResults.add(result);
        break;
      case 'test':
        testResults.add(result);
        break;
      case 'cleanup':
        cleanupResults.add(result);
        break;
    }
  }

  Duration get totalDuration => (endTime ?? DateTime.now()).difference(startTime);
}
