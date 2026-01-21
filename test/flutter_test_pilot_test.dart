import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  group('FlutterTestPilot', () {
    test('should create singleton instance', () {
      final instance1 = FlutterTestPilot.instance;
      final instance2 = FlutterTestPilot.instance;
      
      expect(instance1, equals(instance2));
    });

    test('TestStatus extension should work correctly', () {
      expect(TestStatus.passed.isPassed, isTrue);
      expect(TestStatus.failed.isFailed, isTrue);
      expect(TestStatus.running.isRunning, isTrue);
      expect(TestStatus.skipped.isSkipped, isTrue);
    });

    test('TestGroup should be created with required parameters', () {
      final suite = TestSuite(
        name: 'Test Suite',
        description: 'A test suite',
        steps: [],
      );
      
      final group = TestGroup(
        name: 'Test Group',
        description: 'A test group',
        suites: [suite],
        stopOnFailure: true,
      );
      
      expect(group.name, equals('Test Group'));
      expect(group.description, equals('A test group'));
      expect(group.suites.length, equals(1));
      expect(group.stopOnFailure, isTrue);
    });
  });
}
