// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_test_pilot_example/main.dart';
// import 'package:integration_test/integration_test.dart';
//
// import 'package:flutter_test_pilot/flutter_test_pilot.dart';
//
// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
//   group('Flutter Test Pilot Integration Tests', () {
//     testWidgets('Run Health Claim Test Suite', (WidgetTester tester) async {
//       // Initialize the test pilot
//       final testPilot = FlutterTestPilot();
//       testPilot.initialize(tester);
//
//       // Pump your app
//       await tester.pumpWidget(HealthcareClaimsApp());
//
//       // Load test configuration from JSON file
//       final testSuite = await FlutterTestPilot.loadTestSuite(
//         'integration_test/test_config.json'
//       );
//
//       // Run the complete test suite
//       final result = await testPilot.runTestSuite(testSuite);
//
//       // Save HTML report
//       await result.saveHtmlReport('integration_test/test_report.html');
//
//       // Print results to console
//       print('\n=== TEST SUITE RESULTS ===');
//       print('Suite: ${result.suiteName}');
//       print('Overall Result: ${result.passed ? "PASSED" : "FAILED"}');
//       print('Tests: ${result.results.where((r) => r.passed).length}/${result.results.length} passed');
//
//       for (final testResult in result.results) {
//         print('\nTest: ${testResult.testName} - ${testResult.passed ? "PASSED" : "FAILED"}');
//
//         if (!testResult.passed) {
//           for (final step in testResult.steps) {
//             if (!step.passed) {
//               print('  ❌ ${step.stepName}: ${step.message}');
//               if (step.expectedValues != null && step.actualValues != null) {
//                 print('     Expected: ${step.expectedValues}');
//                 print('     Actual: ${step.actualValues}');
//               }
//             }
//           }
//         }
//       }
//
//       // Assert that all tests passed (optional)
//       expect(result.passed, isTrue, reason: 'All tests should pass');
//     });
//   });
// }