import 'step_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Base class for all test actions
abstract class TestAction {
  const TestAction();

  Future<StepResult> execute(WidgetTester tester);

  String get description;
}
