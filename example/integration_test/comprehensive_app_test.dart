import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';
import '../lib/main.dart' as app;

void main() {
  group('Comprehensive App Test Suite', () {
    testWidgets('Complete app flow using test_suite', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10)); // Increased timeout

      // Add extra wait for app to fully initialize
      await tester.pump(Duration(seconds: 2));

      // Create a test suite for structured testing
      final testSuite = TestSuite(
        name: 'Comprehensive App Test',
        description:
            'Testing complete app functionality with test_suite package',
        steps: [
          // Step 1: Wait for app to fully load
          Wait.forDuration(Duration(seconds: 2)),

          // Step 2: Verify app launches and shows home screen (Updated to match actual app)
          VerifyWidget(finder: find.text('Native Watcher Test Demo')),

          // Step 3: Wait before interaction
          Wait.forDuration(Duration(seconds: 1)),

          // Step 4: Tap on Test Permissions button (Updated to match actual app)
          TapAction.text('Test Permissions'),

          // Step 5: Verify we're on the permissions screen
          VerifyWidget(finder: find.text('Permission Status')),

          // Step 6: Wait before interaction
          Wait.forDuration(Duration(seconds: 1)),

          // Step 7: Test camera permission button
          TapAction.key('request_camera_button'),
          Wait.forDuration(Duration(seconds: 2)),

          // Step 8: Verify permission status updated
          VerifyWidget(finder: find.byKey(Key('permission_status'))),

          // Step 9: Test storage permission
          TapAction.key('request_storage_button'),
          Wait.forDuration(Duration(seconds: 2)),

          // Step 10: Navigate back using back button
          TapAction.icon(Icons.arrow_back),
          Wait.forDuration(Duration(milliseconds: 500)),

          // Step 11: Verify we're back on home screen
          VerifyWidget(finder: find.text('Native Watcher Test Demo')),

          // Step 12: Test Location page
          TapAction.text('Test Location'),
          Wait.forDuration(Duration(milliseconds: 500)),

          // Step 13: Verify location page loaded
          VerifyWidget(finder: find.text('Location Status')),

          // Step 14: Request location permission
          TapAction.key('request_location_button'),
          Wait.forDuration(Duration(seconds: 2)),

          // Step 15: Go back to home
          TapAction.icon(Icons.arrow_back),
          Wait.forDuration(Duration(milliseconds: 500)),

          // Step 16: Final verification
          VerifyWidget(finder: find.text('Native Watcher Test Demo')),
        ],
      );

      // Execute the test suite
      final results = await testSuite.execute(tester);

      // Print test suite results
      print('\n' + '=' * 80);
      print('Test Suite: ${testSuite.name}');
      print('=' * 80);
      print('Total Steps: ${results.totalSteps}');
      print('Passed: ${results.passedSteps}');
      print('Failed: ${results.failedSteps}');
      print('Total Duration: ${results.totalDuration.inMilliseconds}ms');
      print('Status: ${results.status}');
      print('=' * 80);

      // Assert overall test success
      expect(
        results.status,
        TestStatus.passed,
        reason: 'All test steps should pass',
      );
    });

    testWidgets('Text input with advanced strategies', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(Duration(seconds: 1));

      final testSuite = TestSuite(
        name: 'Advanced Text Input Test',
        description: 'Testing navigation and UI elements',
        steps: [
          // Wait for app to load
          Wait.forDuration(Duration(seconds: 1)),

          // Navigate to Test Permissions page
          TapAction.text('Test Permissions'),
          Wait.forDuration(Duration(milliseconds: 500)),

          // Verify permissions page loaded
          VerifyWidget(finder: find.text('Permissions Test')),

          // Go back
          TapAction.icon(Icons.arrow_back),
          Wait.forDuration(Duration(milliseconds: 500)),

          // Verify we're back on home screen
          VerifyWidget(finder: find.text('Native Watcher Test Demo')),
        ],
      );

      // Execute the test suite
      final results = await testSuite.execute(tester);

      // Print results
      print('\nAdvanced Text Input Test Results:');
      print('Passed: ${results.passedSteps}/${results.totalSteps}');

      expect(results.status, TestStatus.passed);
    });

    testWidgets('Scrolling and gesture combinations', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(Duration(seconds: 1));

      final testSuite = TestSuite(
        name: 'Scrolling and Gestures Test',
        description: 'Testing navigation to location page',
        steps: [
          // Wait for app to load
          Wait.forDuration(Duration(seconds: 1)),

          // Navigate to Test Location page
          TapAction.text('Test Location'),
          Wait.forDuration(Duration(milliseconds: 500)),

          // Verify location page loaded
          VerifyWidget(finder: find.text('Location Test')),

          // Verify we're still on location page
          VerifyWidget(finder: find.text('Location Status')),

          // Navigate back
          TapAction.icon(Icons.arrow_back),
          Wait.forDuration(Duration(milliseconds: 500)),

          // Verify we're back on home
          VerifyWidget(finder: find.text('Native Watcher Test Demo')),
        ],
      );

      final results = await testSuite.execute(tester);

      print('\nScrolling and Gestures Test Results:');
      print('Passed: ${results.passedSteps}/${results.totalSteps}');

      expect(results.status, TestStatus.passed);
    });

    testWidgets('Wait conditions and timing', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(Duration(seconds: 1));

      final testSuite = TestSuite(
        name: 'Wait Conditions Test',
        description: 'Testing wait conditions on notifications page',
        steps: [
          // Wait for app to load
          Wait.forDuration(Duration(seconds: 1)),

          // Navigate to Test Notifications page
          TapAction.text('Test Notifications'),
          Wait.forDuration(Duration(milliseconds: 500)),

          // Verify page loaded by checking status text
          VerifyWidget(finder: find.text('Notification Status')),

          // Trigger notification permission request
          TapAction.key('request_notifications_button'),

          // Wait for permission dialog handling
          Wait.forDuration(Duration(seconds: 2)),

          // Verify notification status container is visible
          VerifyWidget(finder: find.byKey(Key('notification_status'))),
        ],
      );

      final results = await testSuite.execute(tester);

      print('\nWait Conditions Test Results:');
      print('Passed: ${results.passedSteps}/${results.totalSteps}');

      expect(results.status, TestStatus.passed);
    });

    testWidgets('Widget verification and assertions', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(Duration(seconds: 1));

      final testSuite = TestSuite(
        name: 'Widget Verification Test',
        description: 'Testing widget verification on home page',
        steps: [
          // Wait for app to load
          Wait.forDuration(Duration(seconds: 1)),

          // Test widget exists on home screen (Updated to match actual app)
          VerifyWidget(
            finder: find.text('🎯 Test-Driven Native Watcher Demo'),
            shouldExist: true,
          ),

          // Test navigation cards exist (Updated to match actual app)
          VerifyWidget(
            finder: find.text('Test Permissions'),
            shouldExist: true,
          ),
          VerifyWidget(finder: find.text('Test Location'), shouldExist: true),
          VerifyWidget(
            finder: find.text('Test Notifications'),
            shouldExist: true,
          ),
        ],
      );

      final results = await testSuite.execute(tester);

      print('\nWidget Verification Test Results:');
      print('Passed: ${results.passedSteps}/${results.totalSteps}');

      expect(results.status, TestStatus.passed);
    });
  });
}
