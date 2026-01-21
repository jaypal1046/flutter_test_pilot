import 'step_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Base class for all test actions
abstract class TestAction {
  const TestAction();

  Future<StepResult> execute(WidgetTester tester);

  String get description;
}

/// Custom action that allows you to define your own test logic
class CustomAction extends TestAction {
  final Future<StepResult> Function(WidgetTester tester) action;
  final String _description;

  const CustomAction({required this.action, required String description})
    : _description = description;

  @override
  Future<StepResult> execute(WidgetTester tester) async {
    return await action(tester);
  }

  @override
  String get description => _description;
}
