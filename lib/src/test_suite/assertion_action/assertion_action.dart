
// import '../step_result.dart';
// import '../test_action.dart';

// /// Assert conditions
// class Assert extends TestAction {
//   final AssertionCondition condition;

//   const Assert._(this.condition);

//   /// Assert variable value
//   static VariableAssertion variable(String variableName) {
//     return VariableAssertion(variableName);
//   }

//   /// Assert widget state
//   static WidgetAssertion widget(String identifier) {
//     return WidgetAssertion(identifier);
//   }

//   /// Assert text appears
//   static TextAssertion text(String text) {
//     return TextAssertion(text);
//   }

//   /// Assert field value
//   static FieldAssertion field(String fieldIdentifier) {
//     return FieldAssertion(fieldIdentifier);
//   }

//   /// Assert API call
//   static ApiAssertion api(String endpoint) {
//     return ApiAssertion(endpoint);
//   }

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     return await condition.execute(tester);
//   }

//   @override
//   String get description => condition.description;
// }

// abstract class AssertionCondition extends TestAction {
//   // AssertionCondition is also a TestAction
// }

// class VariableAssertion extends AssertionCondition {
//   final String variableName;

//    VariableAssertion(this.variableName);

//   Assert equals(dynamic expectedValue) {
//     return Assert._(_VariableEquals(variableName, expectedValue));
//   }

//   Assert isGreaterThan(num value) {
//     return Assert._(_VariableGreaterThan(variableName, value));
//   }

//   Assert contains(String substring) {
//     return Assert._(_VariableContains(variableName, substring));
//   }

//   Assert isOneOf(List<dynamic> values) {
//     return Assert._(_VariableOneOf(variableName, values));
//   }

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     throw UnimplementedError('Use specific assertion methods like equals()');
//   }

//   @override
//   String get description => 'Variable assertion for $variableName';
// }

// class _VariableEquals extends AssertionCondition {
//   final String variableName;
//   final dynamic expectedValue;

//   const _VariableEquals(this.variableName, this.expectedValue);

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();

//     try {
//       final actualValue = GuardianGlobal.getVariable(variableName);

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

//   @override
//   String get description => 'Assert variable "$variableName" equals "$expectedValue"';
// }

// class _VariableGreaterThan extends AssertionCondition {
//   final String variableName;
//   final num threshold;

//   const _VariableGreaterThan(this.variableName, this.threshold);

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();

//     try {
//       final actualValue = GuardianGlobal.getVariable(variableName);

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

//   @override
//   String get description => 'Assert variable "$variableName" > $threshold';
// }

// class _VariableContains extends AssertionCondition {
//   final String variableName;
//   final String substring;

//   const _VariableContains(this.variableName, this.substring);

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();

//     try {
//       final actualValue = GuardianGlobal.getVariable(variableName);

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

//   @override
//   String get description => 'Assert variable "$variableName" contains "$substring"';
// }

// class _VariableOneOf extends AssertionCondition {
//   final String variableName;
//   final List<dynamic> values;

//   const _VariableOneOf(this.variableName, this.values);

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();

//     try {
//       final actualValue = GuardianGlobal.getVariable(variableName);

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

//   @override
//   String get description => 'Assert variable "$variableName" is one of $values';
// }

// class WidgetAssertion extends AssertionCondition {
//   final String identifier;

//   const WidgetAssertion(this.identifier);

//   Assert isVisible() {
//     return Assert._(_WidgetVisible(identifier));
//   }

//   Assert isHidden() {
//     return Assert._(_WidgetHidden(identifier));
//   }

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     throw UnimplementedError('Use specific assertion methods like isVisible()');
//   }

//   @override
//   String get description => 'Widget assertion for $identifier';
// }

// class _WidgetVisible extends AssertionCondition {
//   final String identifier;

//   const _WidgetVisible(this.identifier);

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();

//     try {
//       final finder = find.text(identifier);

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

//   @override
//   String get description => 'Assert widget "$identifier" is visible';
// }

// class _WidgetHidden extends AssertionCondition {
//   final String identifier;

//   const _WidgetHidden(this.identifier);

//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();

//     try {
//       final finder = find.text(identifier);

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

//   @override
//   String get description => 'Assert widget "$identifier" is hidden';
// }

