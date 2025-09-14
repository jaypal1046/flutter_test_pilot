// import '../step_result.dart';
// import '../test_action.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// class Type extends TestAction {
//   final String fieldIdentifier;
//   final String textToType;
//   final bool clear;
//
//   const Type._(this.fieldIdentifier, this.textToType, {this.clear = true});
//
//   /// Type into a field identified by key or text
//   factory Type.into(String fieldIdentifier) {
//     return _TypeBuilder(fieldIdentifier);
//   }
//
//   @override
//   Future<StepResult> execute(WidgetTester tester) async {
//     final stopwatch = Stopwatch()..start();
//
//     try {
//       // Find the text field
//       Finder finder;
//
//       // Try finding by key first
//       final keyFinder = find.byKey(Key(fieldIdentifier));
//       if (tester.any(keyFinder)) {
//         finder = keyFinder;
//       } else {
//         // Try finding by looking for TextField with hint text or label
//         finder = find.byWidgetPredicate((widget) {
//           if (widget is TextField) {
//             return widget.decoration?.hintText == fieldIdentifier ||
//                 widget.decoration?.labelText == fieldIdentifier;
//           }
//           return false;
//         });
//
//         if (!tester.any(finder)) {
//           // Last resort: find any TextField
//           finder = find.byType(TextField);
//           if (tester.widgetList(finder).length > 1) {
//             throw Exception('Multiple TextFields found. Use a more specific identifier.');
//           }
//         }
//       }
//
//       if (clear) {
//         await tester.enterText(finder, textToType);
//       } else {
//         // Append to existing text
//         final textField = tester.widget<TextField>(finder);
//         final currentText = textField.controller?.text ?? '';
//         await tester.enterText(finder, currentText + textToType);
//       }
//
//       await tester.pumpAndSettle();
//       stopwatch.stop();
//
//       return StepResult.success(
//         message: 'Typed "$textToType" into $fieldIdentifier',
//         duration: stopwatch.elapsed,
//       );
//     } catch (e) {
//       stopwatch.stop();
//       return StepResult.failure('Type failed: $e', duration: stopwatch.elapsed);
//     }
//   }
//
//   @override
//   String get description => 'Type "$textToType" into $fieldIdentifier';
// }
//
// class _TypeBuilder {
//   final String fieldIdentifier;
//
//   const _TypeBuilder(this.fieldIdentifier);
//
//   Type text(String text, {bool clear = true}) {
//     return Type._(fieldIdentifier, text, clear: clear);
//   }
// }