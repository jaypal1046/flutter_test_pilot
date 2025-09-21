import 'step_result.dart';
import 'test_status.dart';
enum TestPhase { setup, test, apis, cleanup }
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

  void addStepResult(TestPhase phase, StepResult result) {
    switch (phase) {
      case TestPhase.setup:
        setupResults.add(result);
        break;
      case TestPhase.test:
        testResults.add(result);
        break;
      case TestPhase.cleanup:
        cleanupResults.add(result);
        break;
      case TestPhase.apis:
        cleanupResults.add(result);
        break;  
    }
  }

  Duration get totalDuration => (endTime ?? DateTime.now()).difference(startTime);
}
