
import 'package:flutter_test/flutter_test.dart';
import 'test_action.dart';
import 'test_result.dart';
import 'test_status.dart';

/// Main TestSuite class that defines a complete test scenario
class TestSuite {
  final String name;
  final String? description;
  final List<TestAction> setup;
  final List<TestAction> steps;
  final List<TestAction> cleanup;
  final Duration? timeout;
  final Map<String, dynamic>? metadata;

  const TestSuite({
    required this.name,
    this.description,
    this.setup = const [],
    required this.steps,
    this.cleanup = const [],
    this.timeout,
    this.metadata,
  });

  /// Execute the test suite
  Future<TestResult> execute(WidgetTester tester) async {
    final result = TestResult(suiteName: name);

    try {
      // Execute setup steps
      for (final action in setup) {
        await _executeAction(action, tester, result, 'setup');
      }

      // Execute main test steps
      for (final action in steps) {
        await _executeAction(action, tester, result, 'test');
      }

      result.status = TestStatus.passed;

    } catch (e) {
      result.status = TestStatus.failed;
      result.error = e.toString();
    } finally {
      // Always run cleanup
      try {
        for (final action in cleanup) {
          await _executeAction(action, tester, result, 'cleanup');
        }
      } catch (e) {
        result.cleanupError = e.toString();
      }
    }

    return result;
  }

  Future<void> _executeAction(TestAction action, WidgetTester tester, TestResult result, String phase) async {
    final stepResult = await action.execute(tester);
    result.addStepResult(phase, stepResult);

    if (!stepResult.success) {
      throw Exception('${action.runtimeType} failed: ${stepResult.error}');
    }
  }
}









// // =============================================================================
// // UI INTERACTION ACTIONS
// // =============================================================================
//
//
//
// /// Type text into a widget
//
//
// /// Scroll action
// class Scroll extends TestAction {
//   final String direction;
//   final double? amount;
//   final String? untilVisible;
//
//   const Scroll._(this.direction, {this.amount, this.untilVisible});
//
//   factory Scroll.up({double? amount}) => Scroll._('up', amount: amount);
//   factory Scroll.down({double? amount}) => Scroll._('down', amount: amount);
//   factory Scroll.left({double? amount}) => Scroll._('left', amount: amount);
//   factory Scroll.right({double? amount}) => Scroll._('right', amount: amount);
//
//   factory Scroll.to(String position) {
//     switch (position.toLowerCase()) {
//       case 'top':
//         return const Scroll._('top');
//       case 'bottom':
//         return const Scroll._('bottom');
//       default:
//         return Scroll._('until_visible', untilVisible: position);
//     }
//   }
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     try {
//       // Implementation would depend on finding scrollable widgets
//       // This is a simplified version
//       final scrollable = find.byType(Scrollable).first;
//
//       switch (direction) {
//         case 'up':
//           await tester.scroll(scrollable, const Offset(0, 300));
//           break;
//         case 'down':
//           await tester.scroll(scrollable, const Offset(0, -300));
//           break;
//         case 'left':
//           await tester.scroll(scrollable, const Offset(300, 0));
//           break;
//         case 'right':
//           await tester.scroll(scrollable, const Offset(-300, 0));
//           break;
//         case 'top':
//           await tester.scroll(scrollable, const Offset(0, 10000));
//           break;
//         case 'bottom':
//           await tester.scroll(scrollable, const Offset(0, -10000));
//           break;
//         case 'until_visible':
//         // Scroll until specific widget is visible
//           if (untilVisible != null) {
//             await tester.scrollUntilVisible(find.text(untilVisible!), 300);
//           }
//           break;
//       }
//
//       await tester.pumpAndSettle();
//       stopwatch.stop();
//
//       return StepResult.success(
//         message: 'Scrolled $direction',
//         duration: stopwatch.elapsed,
//       );
//     } catch (e) {
//       stopwatch.stop();
//       return StepResult.failure('Scroll failed: $e', duration: stopwatch.elapsed);
//     }
//   }
//
//   @override
//   String get description => 'Scroll $direction';
// }
//
// // =============================================================================
// // WAIT ACTIONS
// // =============================================================================
//
// /// Wait for conditions
// class Wait extends TestAction {
//   final WaitCondition condition;
//
//   const Wait._(this.condition);
//
//   /// Wait for a duration
//   factory Wait.for(Duration duration) {
//   return Wait._(_WaitDuration(duration));
//   }
//
//   /// Wait until conditions - returns WaitUntil builder
//   static WaitUntil get until => const WaitUntil();
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//   return await condition.execute(tester);
//   }
//
//   @override
//   String get description => condition.description;
// }
//
// abstract class WaitCondition {
//   Future<StepResult> execute(WidgetTester tester);
//   String get description;
// }
//
// class _WaitDuration extends WaitCondition {
//   final Duration duration;
//
//   const _WaitDuration(this.duration);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     await Future.delayed(duration);
//     await tester.pumpAndSettle();
//     stopwatch.stop();
//
//     return StepResult.success(
//       message: 'Waited for ${duration.inMilliseconds}ms',
//       duration: stopwatch.elapsed,
//     );
//   }
//
//   @override
//   String get description => 'Wait for ${duration.inMilliseconds}ms';
// }
//
// class WaitUntil {
//   const WaitUntil();
//
//   Wait widgetExists(String identifier) {
//     return Wait._(_WaitUntilWidgetExists(identifier));
//   }
//
//   Wait apiCallCompletes(String endpoint) {
//     return Wait._(_WaitUntilApiCall(endpoint));
//   }
//
//   Wait pageLoads<T>() {
//     return Wait._(_WaitUntilPageLoads<T>());
//   }
//
//   Wait animationFinishes() {
//     return Wait._(_WaitUntilAnimationFinishes());
//   }
// }
//
// class _WaitUntilWidgetExists extends WaitCondition {
//   final String identifier;
//
//   const _WaitUntilWidgetExists(this.identifier);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     // Wait up to 10 seconds for widget to exist
//     for (int i = 0; i < 100; i++) {
//       await tester.pump(const Duration(milliseconds: 100));
//
//       final finder = find.text(identifier);
//       if (tester.any(finder)) {
//         stopwatch.stop();
//         return StepResult.success(
//           message: 'Widget "$identifier" appeared',
//           duration: stopwatch.elapsed,
//         );
//       }
//     }
//
//     stopwatch.stop();
//     return StepResult.failure(
//       'Widget "$identifier" did not appear within 10 seconds',
//       duration: stopwatch.elapsed,
//     );
//   }
//
//   @override
//   String get description => 'Wait until widget "$identifier" exists';
// }
//
// class _WaitUntilApiCall extends WaitCondition {
//   final String endpoint;
//
//   const _WaitUntilApiCall(this.endpoint);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     // Implementation would check GuardianGlobal for API calls
//     // This is a simplified version
//     await Future.delayed(const Duration(milliseconds: 500));
//     await tester.pumpAndSettle();
//     stopwatch.stop();
//
//     return StepResult.success(
//       message: 'API call to $endpoint completed',
//       duration: stopwatch.elapsed,
//     );
//   }
//
//   @override
//   String get description => 'Wait until API call "$endpoint" completes';
// }
//
// class _WaitUntilPageLoads<T> extends WaitCondition {
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     for (int i = 0; i < 50; i++) {
//       await tester.pump(const Duration(milliseconds: 100));
//
//       final finder = find.byType(T);
//       if (tester.any(finder)) {
//         stopwatch.stop();
//         return StepResult.success(
//           message: 'Page ${T.toString()} loaded',
//           duration: stopwatch.elapsed,
//         );
//       }
//     }
//
//     stopwatch.stop();
//     return StepResult.failure(
//       'Page ${T.toString()} did not load within 5 seconds',
//       duration: stopwatch.elapsed,
//     );
//   }
//
//   @override
//   String get description => 'Wait until page ${T.toString()} loads';
// }
//
// class _WaitUntilAnimationFinishes extends WaitCondition {
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     await tester.pumpAndSettle();
//     stopwatch.stop();
//
//     return StepResult.success(
//       message: 'Animations finished',
//       duration: stopwatch.elapsed,
//     );
//   }
//
//   @override
//   String get description => 'Wait until animations finish';
// }
//
// // =============================================================================
// // ASSERTION ACTIONS
// // =============================================================================
//
// /// Assert conditions
// class Assert extends TestAction {
//   final AssertionCondition condition;
//
//   const Assert._(this.condition);
//
//   /// Assert variable value
//   static VariableAssertion variable(String variableName) {
//     return VariableAssertion(variableName);
//   }
//
//   /// Assert widget state
//   static WidgetAssertion widget(String identifier) {
//     return WidgetAssertion(identifier);
//   }
//
//   /// Assert text appears
//   static TextAssertion text(String text) {
//     return TextAssertion(text);
//   }
//
//   /// Assert field value
//   static FieldAssertion field(String fieldIdentifier) {
//     return FieldAssertion(fieldIdentifier);
//   }
//
//   /// Assert API call
//   static ApiAssertion api(String endpoint) {
//     return ApiAssertion(endpoint);
//   }
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     return await condition.execute(tester);
//   }
//
//   @override
//   String get description => condition.description;
// }
//
// abstract class AssertionCondition extends TestAction {
//   // AssertionCondition is also a TestAction
// }
//
// class VariableAssertion extends AssertionCondition {
//   final String variableName;
//
//   const VariableAssertion(this.variableName);
//
//   Assert equals(dynamic expectedValue) {
//     return Assert._(_VariableEquals(variableName, expectedValue));
//   }
//
//   Assert isGreaterThan(num value) {
//     return Assert._(_VariableGreaterThan(variableName, value));
//   }
//
//   Assert contains(String substring) {
//     return Assert._(_VariableContains(variableName, substring));
//   }
//
//   Assert isOneOf(List<dynamic> values) {
//     return Assert._(_VariableOneOf(variableName, values));
//   }
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     throw UnimplementedError('Use specific assertion methods like equals()');
//   }
//
//   @override
//   String get description => 'Variable assertion for $variableName';
// }
//
// class _VariableEquals extends AssertionCondition {
//   final String variableName;
//   final dynamic expectedValue;
//
//   const _VariableEquals(this.variableName, this.expectedValue);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     try {
//       final actualValue = GuardianGlobal.getVariable(variableName);
//
//       if (actualValue == expectedValue) {
//         stopwatch.stop();
//         return StepResult.success(
//           message: 'Variable "$variableName" equals "$expectedValue"',
//           duration: stopwatch.elapsed,
//         );
//       } else {
//         stopwatch.stop();
//         return StepResult.failure(
//           'Variable "$variableName" expected "$expectedValue", got "$actualValue"',
//           duration: stopwatch.elapsed,
//         );
//       }
//     } catch (e) {
//       stopwatch.stop();
//       return StepResult.failure(
//         'Variable assertion failed: $e',
//         duration: stopwatch.elapsed,
//       );
//     }
//   }
//
//   @override
//   String get description => 'Assert variable "$variableName" equals "$expectedValue"';
// }
//
// class _VariableGreaterThan extends AssertionCondition {
//   final String variableName;
//   final num threshold;
//
//   const _VariableGreaterThan(this.variableName, this.threshold);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     try {
//       final actualValue = GuardianGlobal.getVariable(variableName);
//
//       if (actualValue is num && actualValue > threshold) {
//         stopwatch.stop();
//         return StepResult.success(
//           message: 'Variable "$variableName" ($actualValue) > $threshold',
//           duration: stopwatch.elapsed,
//         );
//       } else {
//         stopwatch.stop();
//         return StepResult.failure(
//           'Variable "$variableName" ($actualValue) is not > $threshold',
//           duration: stopwatch.elapsed,
//         );
//       }
//     } catch (e) {
//       stopwatch.stop();
//       return StepResult.failure(
//         'Variable assertion failed: $e',
//         duration: stopwatch.elapsed,
//       );
//     }
//   }
//
//   @override
//   String get description => 'Assert variable "$variableName" > $threshold';
// }
//
// class _VariableContains extends AssertionCondition {
//   final String variableName;
//   final String substring;
//
//   const _VariableContains(this.variableName, this.substring);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     try {
//       final actualValue = GuardianGlobal.getVariable(variableName);
//
//       if (actualValue is String && actualValue.contains(substring)) {
//         stopwatch.stop();
//         return StepResult.success(
//           message: 'Variable "$variableName" contains "$substring"',
//           duration: stopwatch.elapsed,
//         );
//       } else {
//         stopwatch.stop();
//         return StepResult.failure(
//           'Variable "$variableName" ("$actualValue") does not contain "$substring"',
//           duration: stopwatch.elapsed,
//         );
//       }
//     } catch (e) {
//       stopwatch.stop();
//       return StepResult.failure(
//         'Variable assertion failed: $e',
//         duration: stopwatch.elapsed,
//       );
//     }
//   }
//
//   @override
//   String get description => 'Assert variable "$variableName" contains "$substring"';
// }
//
// class _VariableOneOf extends AssertionCondition {
//   final String variableName;
//   final List<dynamic> values;
//
//   const _VariableOneOf(this.variableName, this.values);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     try {
//       final actualValue = GuardianGlobal.getVariable(variableName);
//
//       if (values.contains(actualValue)) {
//         stopwatch.stop();
//         return StepResult.success(
//           message: 'Variable "$variableName" is one of $values',
//           duration: stopwatch.elapsed,
//         );
//       } else {
//         stopwatch.stop();
//         return StepResult.failure(
//           'Variable "$variableName" ("$actualValue") is not one of $values',
//           duration: stopwatch.elapsed,
//         );
//       }
//     } catch (e) {
//       stopwatch.stop();
//       return StepResult.failure(
//         'Variable assertion failed: $e',
//         duration: stopwatch.elapsed,
//       );
//     }
//   }
//
//   @override
//   String get description => 'Assert variable "$variableName" is one of $values';
// }
//
// class WidgetAssertion extends AssertionCondition {
//   final String identifier;
//
//   const WidgetAssertion(this.identifier);
//
//   Assert isVisible() {
//     return Assert._(_WidgetVisible(identifier));
//   }
//
//   Assert isHidden() {
//     return Assert._(_WidgetHidden(identifier));
//   }
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     throw UnimplementedError('Use specific assertion methods like isVisible()');
//   }
//
//   @override
//   String get description => 'Widget assertion for $identifier';
// }
//
// class _WidgetVisible extends AssertionCondition {
//   final String identifier;
//
//   const _WidgetVisible(this.identifier);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     try {
//       final finder = find.text(identifier);
//
//       if (tester.any(finder)) {
//         stopwatch.stop();
//         return StepResult.success(
//           message: 'Widget "$identifier" is visible',
//           duration: stopwatch.elapsed,
//         );
//       } else {
//         stopwatch.stop();
//         return StepResult.failure(
//           'Widget "$identifier" is not visible',
//           duration: stopwatch.elapsed,
//         );
//       }
//     } catch (e) {
//       stopwatch.stop();
//       return StepResult.failure(
//         'Widget visibility assertion failed: $e',
//         duration: stopwatch.elapsed,
//       );
//     }
//   }
//
//   @override
//   String get description => 'Assert widget "$identifier" is visible';
// }
//
// class _WidgetHidden extends AssertionCondition {
//   final String identifier;
//
//   const _WidgetHidden(this.identifier);
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     try {
//       final finder = find.text(identifier);
//
//       if (!tester.any(finder)) {
//         stopwatch.stop();
//         return StepResult.success(
//           message: 'Widget "$identifier" is hidden',
//           duration: stopwatch.elapsed,
//         );
//       } else {
//         stopwatch.stop();
//         return StepResult.failure(
//           'Widget "$identifier" is visible (expected hidden)',
//           duration: stopwatch.elapsed,
//         );
//       }
//     } catch (e) {
//       stopwatch.stop();
//       return StepResult.failure(
//         'Widget visibility assertion failed: $e',
//         duration: stopwatch.elapsed,
//       );
//     }
//   }
//
//   @override
//   String get description => 'Assert widget "$identifier" is hidden';
// }
//
