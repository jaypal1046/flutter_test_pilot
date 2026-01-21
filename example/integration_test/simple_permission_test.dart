
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';
import '../lib/main.dart' as app;

void main() {
  testWidgets('Simple Location Permission Test - See Dialog Appear', (
    WidgetTester tester,
  ) async {
    // Launch the app
    app.main();
    await tester.pumpAndSettle(Duration(seconds: 3));

    print('\n🎬 Starting permission test - Watch your emulator screen!\n');

    final testSuite = TestSuite(
      name: 'Visual Permission Dialog Test',
      description: 'Watch the permission dialog appear and get auto-handled',
      steps: [
        // Wait for app to load
        Wait.forDuration(Duration(seconds: 2)),

        // Navigate to Location page
        TapAction.text('Test Location'),
        Wait.forDuration(Duration(seconds: 1)),

        // Verify we're on location page
        VerifyWidget(finder: find.text('Location Test')),

        // 🎯 THIS WILL TRIGGER THE PERMISSION DIALOG!
        // Watch your emulator screen when this runs
        TapAction.key('request_location_button'),
        
        // Give time to see the dialog (before watcher handles it)
        Wait.forDuration(Duration(milliseconds: 500)),

        // Verify permission was granted (watcher handled it)
        Wait.forDuration(Duration(seconds: 2)),
        
        // Check if permission granted text appears
        VerifyWidget(
          finder: find.textContaining('granted'),
          shouldExist: true,
        ),
      ],
    );

    final results = await testSuite.execute(tester);

    print('\n📊 Test Results:');
    print('Total Steps: ${results.totalSteps}');
    print('Passed: ${results.passedSteps}');
    print('Status: ${results.status}');

    expect(results.status, TestStatus.passed);
  });
}
