import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';
import 'package:flutter_test_pilot/src/nav/global_nav.dart';
import 'package:flutter_test_pilot_example/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.testTextInput.register();

  group('Flutter Test Pilot Integration Tests', () {
    testWidgets('Simple App Launch Test', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle(Duration(seconds: 10));
      FlutterTestPilot.initialize(tester);

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(TestPilotNavigator.isReady, isTrue);

      final defaultS = TestSuite(
        name: 'User Login Flow',
        description: 'Complete login process from start to finish',
        apis: [
          // Api.
        ],

        setup: [
          // Actions to run before main test
          // ClearUserData(),
          // SetupMockServer(),
        ],

        steps: [Tap.text("Go to Claims Page")],

        cleanup: [
          // Actions to run after test
          // Logout(),
          // ClearCache(),
        ],
      );

      await TestPilotRunner.runSuite(tester, defaultS);
    });
  });
}

// // example_api_tests.dart

// /// Example usage of the API Observer framework
// class ExampleApiTests {

//   /// 1. Basic Setup - Initialize API Observer with Dio
//   static void setupApiObserver() {
//     final dio = Dio();

//     // Initialize the API observer to capture all HTTP calls
//     ApiObserverManager.initialize(dio);

//     // Optional: Listen to test results in real-time
//     ApiObserverManager.instance.testResults.listen((result) {
//       print('API Test Result: ${result.apiId} - ${result.isSuccess ? "PASSED" : "FAILED"}');
//       if (!result.isSuccess) {
//         for (final failure in result.failures) {
//           print('  - ${failure.fieldPath}: ${failure.message}');
//         }
//       }
//     });
//   }

//   /// 2. Simple GET API Test
//   static ApiTest createSimpleGetTest() {
//     return Api.get(
//       id: 'get_user_profile',
//       urlPattern: r'/api/users/\d+', // Regex pattern to match /api/users/123
//       expectedStatus: 200,
//       responseChecks: [
//         ResponseCheck('id', IntChecker(min: 1)),
//         ResponseCheck('name', StringChecker(minLength: 1)),
//         ResponseCheck('email', StringChecker(pattern: RegExp(r'^[^@]+@[^@]+\.[^@]+$'))),
//         ResponseCheck('isActive', BoolChecker()),
//       ],
//     );
//   }

//   /// 3. POST API Test with Request and Response Validation
//   static ApiTest createPostUserTest() {
//     return Api.post(
//       id: 'create_user',
//       urlPattern: r'/api/users',
//       expectedStatus: 201,
//       requestChecks: [
//         RequestCheck('name', StringChecker(minLength: 2, maxLength: 50)),
//         RequestCheck('email', StringChecker(pattern: RegExp(r'^[^@]+@[^@]+\.[^@]+$'))),
//         RequestCheck('age', IntChecker(min: 18, max: 120)),
//       ],
//       responseChecks: [
//         ResponseCheck('id', IntChecker(min: 1)),
//         ResponseCheck('name', StringChecker()),
//         ResponseCheck('email', StringChecker()),
//         ResponseCheck('createdAt', StringChecker()), // ISO date string
//         ResponseCheck('status', StringChecker(exactValue: 'active')),
//       ],
//     );
//   }

//   /// 4. Complex Nested Object Validation
//   static ApiTest createNestedObjectTest() {
//     return Api.get(
//       id: 'get_user_with_address',
//       urlPattern: r'/api/users/\d+/profile',
//       expectedStatus: 200,
//       responseChecks: [
//         // Basic user fields
//         ResponseCheck('user/id', IntChecker()),
//         ResponseCheck('user/name', StringChecker()),

//         // Nested address object validation
//         ResponseCheck('user/address/street', StringChecker(minLength: 5)),
//         ResponseCheck('user/address/city', StringChecker(minLength: 2)),
//         ResponseCheck('user/address/zipCode', StringChecker(pattern: RegExp(r'^\d{5}(-\d{4})?$'))),
//         ResponseCheck('user/address/country', StringChecker(exactValue: 'USA')),

//         // Array of phone numbers
//         ResponseCheck('user/phoneNumbers', ListChecker(
//           minLength: 1,
//           maxLength: 3,
//           itemChecker: StringChecker(pattern: RegExp(r'^\+?1?-?\d{3}-?\d{3}-?\d{4}$')),
//         )),

//         // Preferences object
//         ResponseCheck('user/preferences/notifications', BoolChecker()),
//         ResponseCheck('user/preferences/theme', StringChecker(exactValue: 'dark')),
//       ],
//     );
//   }

//   /// 5. List/Array Validation Test
//   static ApiTest createListTest() {
//     return Api.get(
//       id: 'get_users_list',
//       urlPattern: r'/api/users',
//       expectedStatus: 200,
//       responseChecks: [
//         // Validate the users array
//         ResponseCheck('users', ListChecker(
//           minLength: 1,
//           maxLength: 100,
//           itemChecker: ObjectChecker({
//             'id': IntChecker(min: 1),
//             'name': StringChecker(minLength: 1),
//             'email': StringChecker(pattern: RegExp(r'^[^@]+@[^@]+\.[^@]+$')),
//             'isActive': BoolChecker(),
//           }),
//         )),

//         // Validate pagination metadata
//         ResponseCheck('pagination/total', IntChecker(min: 0)),
//         ResponseCheck('pagination/page', IntChecker(min: 1)),
//         ResponseCheck('pagination/limit', IntChecker(min: 1, max: 100)),
//       ],
//     );
//   }

//   /// 6. Custom Validation Logic
//   static ApiTest createCustomValidationTest() {
//     return Api.post(
//       id: 'create_order',
//       urlPattern: r'/api/orders',
//       expectedStatus: 201,
//       responseChecks: [
//         ResponseCheck('orderId', StringChecker(pattern: RegExp(r'^ORD-\d{8}$'))),
//         ResponseCheck('total', CustomChecker(
//           (fieldPath, value) async {
//             if (value is! num) {
//               return ApiValidationResult.failure(
//                 fieldPath,
//                 'Expected number for total amount',
//                 expected: 'number',
//                 actual: value.runtimeType.toString(),
//               );
//             }

//             if (value <= 0) {
//               return ApiValidationResult.failure(
//                 fieldPath,
//                 'Order total must be positive',
//                 expected: '> 0',
//                 actual: value,
//               );
//             }

//             if (value > 10000) {
//               return ApiValidationResult.failure(
//                 fieldPath,
//                 'Order total seems too high',
//                 expected: '≤ 10000',
//                 actual: value,
//               );
//             }

//             return ApiValidationResult.success(fieldPath, 'Valid order total: \$${value}');
//           },
//           'Positive number ≤ 10000',
//         )),

//         // Custom date validation
//         ResponseCheck('createdAt', CustomChecker(
//           (fieldPath, value) async {
//             if (value is! String) {
//               return ApiValidationResult.failure(
//                 fieldPath,
//                 'Expected ISO date string',
//                 actual: value.runtimeType.toString(),
//               );
//             }

//             try {
//               final date = DateTime.parse(value);
//               final now = DateTime.now();

//               if (date.isAfter(now.add(Duration(minutes: 1)))) {
//                 return ApiValidationResult.failure(
//                   fieldPath,
//                   'Created date cannot be in the future',
//                   actual: value,
//                 );
//               }

//               if (date.isBefore(now.subtract(Duration(hours: 1)))) {
//                 return ApiValidationResult.failure(
//                   fieldPath,
//                   'Created date is too old',
//                   actual: value,
//                 );
//               }

//               return ApiValidationResult.success(fieldPath, 'Valid creation date');
//             } catch (e) {
//               return ApiValidationResult.failure(
//                 fieldPath,
//                 'Invalid date format: $e',
//                 actual: value,
//               );
//             }
//           },
//           'Recent ISO date string',
//         )),
//       ],
//     );
//   }

//   /// 7. Exact JSON Matching
//   static ApiTest createExactMatchTest() {
//     return Api.get(
//       id: 'get_system_status',
//       urlPattern: r'/api/status',
//       expectedStatus: 200,
//       exactResponse: {
//         'status': 'healthy',
//         'version': '1.0.0',
//         'uptime': 3600,
//         'services': {
//           'database': 'connected',
//           'cache': 'connected',
//           'queue': 'connected',
//         }
//       },
//     );
//   }

//   /// 8. Error Handling Test
//   static ApiTest createErrorTest() {
//     return Api.get(
//       id: 'get_nonexistent_user',
//       urlPattern: r'/api/users/999999',
//       expectedStatus: 404,
//       responseChecks: [
//         ResponseCheck('error/code', StringChecker(exactValue: 'USER_NOT_FOUND')),
//         ResponseCheck('error/message', StringChecker(minLength: 10)),
//         ResponseCheck('error/timestamp', StringChecker()),
//       ],
//     );
//   }

//   /// 9. Multiple Status Codes Acceptance
//   static ApiTest createFlexibleStatusTest() {
//     return ApiTest(
//       apiId: 'update_user_flexible',
//       method: 'PUT',
//       urlPattern: r'/api/users/\d+',
//       acceptableStatusCodes: [200, 201, 202], // Accept any of these
//       responseChecks: [
//         ResponseCheck('id', IntChecker()),
//         ResponseCheck('updatedAt', StringChecker()),
//       ],
//     );
//   }

//   /// 10. Complete Test Suite Setup
//   static void setupCompleteTestSuite() {
//     // Clear any existing tests
//     ApiObserverManager.instance.clearTests();

//     // Register all tests
//     final tests = [
//       createSimpleGetTest(),
//       createPostUserTest(),
//       createNestedObjectTest(),
//       createListTest(),
//       createCustomValidationTest(),
//       createExactMatchTest(),
//       createErrorTest(),
//       createFlexibleStatusTest(),
//     ];

//     // Execute each test (registers them for monitoring)
//     for (final test in tests) {
//       test.execute(null); // WidgetTester not needed for registration
//     }

//     print('Registered ${tests.length} API tests');
//   }
// }

// /// Example Flutter Widget Test using API Observer
// void main() {
//   group('API Integration Tests', () {
//     late Dio dio;

//     setUpAll(() {
//       // Initialize Dio and API Observer
//       dio = Dio();
//       ApiObserverManager.initialize(dio);
//       ExampleApiTests.setupCompleteTestSuite();
//     });

//     testWidgets('User Profile API Flow', (WidgetTester tester) async {
//       // Your existing widget test code here...
//       // The API calls made during the test will be automatically captured
//       // and validated against the registered tests

//       // Simulate some API interactions
//       await dio.get('/api/users/123');
//       await dio.post('/api/users', data: {
//         'name': 'John Doe',
//         'email': 'john@example.com',
//         'age': 30,
//       });

//       // Wait for async validations to complete
//       await Future.delayed(Duration(milliseconds: 100));

//       // Check test results
//       final results = ApiObserverManager.instance.allTestResults;
//       expect(results.length, greaterThan(0));

//       // Verify specific test passed
//       final getUserResult = results.firstWhere(
//         (r) => r.apiId == 'get_user_profile',
//         orElse: () => throw Exception('get_user_profile test not found'),
//       );

//       expect(getUserResult.isSuccess, isTrue);

//       // Print detailed results
//       for (final result in results) {
//         print('\n--- ${result.apiId} ---');
//         print('Status: ${result.isSuccess ? "PASSED" : "FAILED"}');
//         print('API Call: ${result.apiCall.method} ${result.apiCall.url}');
//         print('Response Status: ${result.apiCall.statusCode}');
//         print('Validations: ${result.passedValidations}/${result.totalValidations} passed');

//         if (!result.isSuccess) {
//           print('Failures:');
//           for (final failure in result.failures) {
//             print('  - ${failure.fieldPath}: ${failure.message}');
//             if (failure.expectedValue != null) {
//               print('    Expected: ${failure.expectedValue}');
//             }
//             if (failure.actualValue != null) {
//               print('    Actual: ${failure.actualValue}');
//             }
//           }
//         }
//       }

//       // Get JSON results for external reporting
//       final jsonResults = ApiObserverManager.instance.getAllTestResultsJson();
//       print('\nJSON Results for external system:');
//       print(jsonResults);
//     });

//     testWidgets('Error Handling Test', (WidgetTester tester) async {
//       try {
//         await dio.get('/api/users/999999');
//       } catch (e) {
//         // Expected error - the test should still validate the error response
//       }

//       await Future.delayed(Duration(milliseconds: 100));

//       final errorResult = ApiObserverManager.instance.allTestResults
//           .firstWhere((r) => r.apiId == 'get_nonexistent_user');

//       expect(errorResult.isSuccess, isTrue); // Should pass because we expect 404
//     });
//   });
// }

// /// Example usage in a real app context
// class RealAppExample {
//   late Dio dio;

//   void initializeApp() {
//     dio = Dio(BaseOptions(
//       baseUrl: 'https://api.example.com',
//       connectTimeout: Duration(seconds: 5),
//       receiveTimeout: Duration(seconds: 3),
//     ));

//     // Add API observer in debug mode
//     if (kDebugMode) {
//       ApiObserverManager.initialize(dio);
//       _setupApiTests();
//     }
//   }

//   void _setupApiTests() {
//     // Register tests for your critical API endpoints
//     final criticalTests = [
//       Api.post(
//         id: 'user_login',
//         urlPattern: r'/auth/login',
//         expectedStatus: 200,
//         requestChecks: [
//           RequestCheck('email', StringChecker(pattern: RegExp(r'^[^@]+@[^@]+\.[^@]+$'))),
//           RequestCheck('password', StringChecker(minLength: 8)),
//         ],
//         responseChecks: [
//           ResponseCheck('token', StringChecker(minLength: 20)),
//           ResponseCheck('user/id', IntChecker()),
//           ResponseCheck('user/role', StringChecker()),
//           ResponseCheck('expiresAt', StringChecker()),
//         ],
//       ),

//       Api.get(
//         id: 'dashboard_data',
//         urlPattern: r'/dashboard',
//         expectedStatus: 200,
//         responseChecks: [
//           ResponseCheck('stats/totalUsers', IntChecker(min: 0)),
//           ResponseCheck('stats/activeUsers', IntChecker(min: 0)),
//           ResponseCheck('recentActivity', ListChecker(maxLength: 10)),
//         ],
//       ),
//     ];

//     for (final test in criticalTests) {
//       test.execute(null);
//     }

//     // Monitor results and send to analytics
//     ApiObserverManager.instance.testResults.listen((result) {
//       if (!result.isSuccess) {
//         _reportApiTestFailure(result);
//       }
//     });
//   }

//   void _reportApiTestFailure(ApiTestResult result) {
//     // Send failure data to your monitoring system
//     final failureData = {
//       'testId': result.apiId,
//       'endpoint': '${result.apiCall.method} ${result.apiCall.url}',
//       'statusCode': result.apiCall.statusCode,
//       'failures': result.failures.map((f) => {
//         'field': f.fieldPath,
//         'message': f.message,
//         'expected': f.expectedValue,
//         'actual': f.actualValue,
//       }).toList(),
//       'timestamp': result.timestamp.toIso8601String(),
//     };

//     // Analytics.reportEvent('api_test_failure', failureData);
//     print('API Test Failure: $failureData');
//   }
// }

// /// Helper class to create common checker patterns
// class CheckerPatterns {
//   // Email validation
//   static StringChecker email() => StringChecker(
//     pattern: RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
//   );

//   // Phone number validation
//   static StringChecker phoneNumber() => StringChecker(
//     pattern: RegExp(r'^\+?1?-?\(?\d{3}\)?-?\d{3}-?\d{4}$'),
//   );

//   // UUID validation
//   static StringChecker uuid() => StringChecker(
//     pattern: RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'),
//   );

//   // ISO date string
//   static StringChecker isoDate() => StringChecker(
//     pattern: RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z?$'),
//   );

//   // Positive integer
//   static IntChecker positiveInt() => IntChecker(min: 1);

//   // Non-negative integer
//   static IntChecker nonNegativeInt() => IntChecker(min: 0);

//   // Pagination object
//   static ObjectChecker pagination() => ObjectChecker({
//     'page': IntChecker(min: 1),
//     'limit': IntChecker(min: 1, max: 100),
//     'total': IntChecker(min: 0),
//     'hasMore': BoolChecker(),
//   });
// }
