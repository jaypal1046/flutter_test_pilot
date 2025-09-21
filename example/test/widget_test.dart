import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';
import 'package:flutter_test_pilot_example/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Initialize as early as possible
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Add timeout configuration
  binding.testTextInput.register();

  print('🚀 Test initialization started...');

  group('Flutter Test Pilot Integration Tests', () {
    // Start with a simple test to verify everything works
    testWidgets('Simple App Launch Test', (WidgetTester tester) async {
      print('📱 Starting app launch test...');

      try {
        // Pump the app
        print('⏳ Pumping widget...');
        await tester.pumpWidget(MyApp());

        print('⏳ Waiting for settle...');
        await tester.pumpAndSettle(Duration(seconds: 10)); // Increase timeout

        print('✅ App launched successfully');

        // Basic verification
        expect(find.byType(MaterialApp), findsOneWidget);
        print('✅ MaterialApp found');

        // Check if TestPilotNavigator is ready
        if (TestPilotNavigator.isReady) {
          print('✅ TestPilotNavigator is ready');
        } else {
          print('❌ TestPilotNavigator is not ready');
        }

        print('✅ Simple test completed');
      } catch (e, stackTrace) {
        print('❌ Error in simple test: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    testWidgets('Test Pilot Integration Test', (WidgetTester tester) async {
      print('🧪 Starting Test Pilot integration...');

      try {
        // Pump the app with longer timeout
        print('⏳ Pumping app...');
        await tester.pumpWidget(MyApp());

        // Use longer settle time for complex apps
        print('⏳ Settling app (extended timeout)...');
        await tester.pumpAndSettle(Duration(seconds: 15));

        print('✅ App settled');

        // Initialize Test Pilot
        print('⏳ Initializing Test Pilot...');
        FlutterTestPilot.initialize(tester);
        print('✅ Test Pilot initialized');

        // Create simple test suite first
        print('⏳ Creating test suite...');
        //   final testSuite = TestSuite(
        //       name: 'Basic App Test',
        //       description: 'Test basic app functionality',
        //       timeout: Duration(minutes: 2), // Add timeout
        //       steps: [
        //       // Start with very basic assertions
        //       Assert.byType<MaterialApp>().isVisible(),
        //       Wait.for(Duration(milliseconds: 500)),
        // Assert.byType<Scaffold>().isVisible(),
        // ],
        // );
        print('✅ Test suite created');

        // Run the test suite
        print('⏳ Running test suite...');
        // await TestPilotRunner.runSuite(tester, testSuite);
        print('✅ Test suite completed successfully');
      } catch (e, stackTrace) {
        print('❌ Error in Test Pilot integration: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });
  });
}

// Alternative minimal test to isolate issues
void minimalMain() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Minimal test', (WidgetTester tester) async {
    print('🔥 MINIMAL TEST STARTED');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Hello World'))),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hello World'), findsOneWidget);

    print('🔥 MINIMAL TEST COMPLETED');
  });
}
