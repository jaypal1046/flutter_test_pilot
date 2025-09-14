// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_test_pilot/flutter_test_pilot.dart';
// import 'package:flutter_test_pilot_example/main.dart';

// import 'package:integration_test/integration_test.dart';


// void main() {
//   group('AutoPilot Health Claim Tests', () {
//     late AutoPilotTester tester;
    
//     setUpAll(() {
//       tester = AutoPilotTester();
//     });
    
//     testWidgets('Run Health Claim Test Suite', (widgetTester) async {
//       // Load your app
//       await widgetTester.pumpWidget(HealthcareClaimsApp());
      
//       // Load test configuration
//       final testSuite = await AutoPilotTester.loadTestSuite(
//         'integration_test/test_config.json'
//       );
      
//       // Run the test suite
//       final result = await tester.runTestSuite(testSuite,widgetTester);
      
//       // Print results
//       print(result.toString());
      
//       // Assert overall success
//       expect(result.passed, isTrue, reason: 'Test suite should pass');
      
//       // Check individual test results
//       for (final testResult in result.results) {
//         print('Test: ${testResult.testName} - ${testResult.passed ? "PASSED" : "FAILED"}');
        
//         if (!testResult.passed) {
//           for (final step in testResult.steps) {
//             if (!step.passed) {
//               print('  Failed step: ${step.stepName} - ${step.message}');
//               if (step.expectedValues != null && step.actualValues != null) {
//                 print('  Expected: ${step.expectedValues}');
//                 print('  Actual: ${step.actualValues}');
//               }
//             }
//           }
//         }
//       }
//     });
//   });
// }


