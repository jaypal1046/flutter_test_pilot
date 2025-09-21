import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';
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
