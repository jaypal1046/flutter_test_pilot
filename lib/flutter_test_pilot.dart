// test_pilot.dart - Main entry point for Test Pilot
export 'package:flutter_test_pilot/flutter_test_pilot.dart';
export 'package:flutter_test_pilot/src/test_pilot_runner.dart';
export 'package:flutter_test_pilot/src/nav/global_nav.dart';
export 'package:flutter_test_pilot/src/test_suite/step_result.dart';
export 'package:flutter_test_pilot/src/test_suite/test_action.dart';
export 'package:flutter_test_pilot/src/test_suite/test_result.dart';
export 'package:flutter_test_pilot/src/test_suite/test_status.dart';
export 'package:flutter_test_pilot/src/test_suite/test_suite.dart';
export 'package:flutter_test_pilot/src/test_suite/nav_action/navgator.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/tap.dart';
export 'package:flutter_test_pilot/src/test_suite/ui_interaction/type.dart';


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/src/nav/global_nav.dart';

import 'src/test_suite/test_result.dart';
import 'src/test_suite/test_status.dart';
import 'src/test_suite/test_suite.dart';

/// Main Test Pilot class - Entry point for all testing functionality
class FlutterTestPilot {
  static FlutterTestPilot? _instance;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static WidgetTester? _currentTester;

  FlutterTestPilot._();

  /// Get singleton instance
  static FlutterTestPilot get instance {
    _instance ??= FlutterTestPilot._();
    return _instance!;
  }

  /// Initialize Test Pilot with navigator key
  static void initialize(GlobalKey<NavigatorState> navigatorKey  ) {

    _navigatorKey = TestPilotNavigator.navigatorKey!;
    print('🚀 Test Pilot initialized with navigator key');
  }

  /// Get current navigator key
  static GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Set current tester (called from within test environment)
  static void setTester(WidgetTester tester) {
    _currentTester = tester;
  }

  /// Get current tester
  static WidgetTester? get currentTester => _currentTester;

  /// Run a single test suite
  Future<TestResult> runSuite(TestSuite suite) async {
    if (_currentTester == null) {
      throw Exception(
        'Test Pilot not properly initialized. Call setTester() first.',
      );
    }

    print('🧪 Running test suite: ${suite.name}');
    final result = await suite.execute(_currentTester!);
    _printTestResult(result);
    return result;
  }

  /// Run multiple test suites as a group
  Future<List<TestResult>> runGroup(TestGroup group) async {
    if (_currentTester == null) {
      throw Exception(
        'Test Pilot not properly initialized. Call setTester() first.',
      );
    }

    print('📋 Running test group: ${group.name}');
    final results = <TestResult>[];

    for (final suite in group.suites) {
      try {
        final result = await suite.execute(_currentTester!);
        results.add(result);
        _printTestResult(result);

        // Stop on first failure if configured
        if (group.stopOnFailure && !result.status.isPassed) {
          print('⚠️ Stopping group execution due to failure');
          break;
        }
      } catch (e) {
        print('❌ Fatal error in suite ${suite.name}: $e');
        break;
      }
    }

    _printGroupSummary(group, results);
    return results;
  }

  /// Helper method to print individual test result
  void _printTestResult(TestResult result) {
    final status = result.status.isPassed ? '✅' : '❌';
    final duration = result.totalDuration.inMilliseconds;

    print('$status ${result.suiteName} - ${duration}ms');

    if (result.error != null) {
      print('   Error: ${result.error}');
    }

    if (result.cleanupError != null) {
      print('   Cleanup Error: ${result.cleanupError}');
    }
  }

  /// Helper method to print group summary
  void _printGroupSummary(TestGroup group, List<TestResult> results) {
    final passed = results.where((r) => r.status.isPassed).length;
    final failed = results.length - passed;
    final totalDuration = results.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.totalDuration,
    );

    print('\n📊 Group Summary: ${group.name}');
    print('   Total: ${results.length}');
    print('   ✅ Passed: $passed');
    print('   ❌ Failed: $failed');
    print('   ⏱️ Duration: ${totalDuration.inMilliseconds}ms\n');
  }
}

// test_group.dart - For grouping multiple test suites
class TestGroup {
  final String name;
  final String? description;
  final List<TestSuite> suites;
  final bool stopOnFailure;
  final Duration? timeout;
  final Map<String, dynamic>? metadata;

  const TestGroup({
    required this.name,
    this.description,
    required this.suites,
    this.stopOnFailure = false,
    this.timeout,
    this.metadata,
  });
}

// test_status_extension.dart - Extension for TestStatus
extension TestStatusExtension on TestStatus {
  bool get isPassed => this == TestStatus.passed;
  bool get isFailed => this == TestStatus.failed;
  bool get isRunning => this == TestStatus.running;
  bool get isSkipped => this == TestStatus.skipped;
}



// Example usage file - test_pilot_example.dart
/*
// In your main.dart, you already have:
final aliceNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Your existing setup - no changes needed!
    TestPilotNavigator.useExistingKey(aliceNavigatorKey);

    return MaterialApp(
      title: 'Test Pilot Demo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
      navigatorKey: aliceNavigatorKey,
    );
  }
}

// In your test file:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/main.dart';
import 'test_pilot.dart';
import 'test_suite.dart';
import 'test_group.dart';
// Import your test actions
import 'test_actions.dart';

void main() {
  group('Test Pilot Examples', () {
    testWidgets('Run single test suite', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Initialize Test Pilot (it will use your existing navigator setup)
      TestPilot.initialize();

      final testSuite = TestSuite(
        name: 'Login Flow Test',
        description: 'Test user login functionality',
        steps: [
          // Your test actions here
          Tap.on('login_button'),
          Wait.until.pageLoads<HomePage>(),
          Assert.text('Welcome').isVisible(),
        ],
      );

      // Run single suite
      await TestPilotRunner.runSuite(tester, testSuite);
    });

    testWidgets('Run test group', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      TestPilot.initialize();

      final loginSuite = TestSuite(
        name: 'Login Test',
        steps: [
          Type.into('email_field', 'test@example.com'),
          Type.into('password_field', 'password123'),
          Tap.on('login_button'),
          Wait.until.pageLoads<DashboardPage>(),
        ],
      );

      final dashboardSuite = TestSuite(
        name: 'Dashboard Test',
        steps: [
          Assert.text('Dashboard').isVisible(),
          Tap.on('menu_button'),
          Wait.for(Duration(milliseconds: 500)),
          Assert.widget('menu_drawer').isVisible(),
        ],
      );

      final testGroup = TestGroup(
        name: 'User Flow Tests',
        suites: [loginSuite, dashboardSuite],
        stopOnFailure: true,
      );

      // Run group of suites
      await TestPilotRunner.runGroup(tester, testGroup);
    });

    testWidgets('Test with navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      TestPilot.initialize();

      final navigationSuite = TestSuite(
        name: 'Navigation Test',
        steps: [
          Navigate.to('/settings'),
          Wait.until.pageLoads<SettingsPage>(),
          Assert.text('Settings').isVisible(),
          Navigate.back(),
          Wait.until.pageLoads<HomePage>(),
          Assert.text('Home').isVisible(),
        ],
      );

      await TestPilotRunner.runSuite(tester, navigationSuite);
    });

    testWidgets('Complex user flow with setup and cleanup', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      TestPilot.initialize();

      final complexSuite = TestSuite(
        name: 'Complete User Journey',
        description: 'Tests the full user journey from login to logout',

        // Setup phase - prepare the test environment
        setup: [
          Navigate.to('/login'),
          Wait.until.pageLoads<LoginPage>(),
        ],

        // Main test steps
        steps: [
          // Login
          Type.into('email_field', 'user@test.com'),
          Type.into('password_field', 'testpass123'),
          Tap.on('login_button'),
          Wait.until.widgetDisappears('loading_spinner'),

          // Verify dashboard
          Wait.until.pageLoads<DashboardPage>(),
          Assert.text('Welcome').isVisible(),

          // Navigate to profile
          Tap.on('profile_tab'),
          Wait.until.pageLoads<ProfilePage>(),
          Assert.text('Profile').isVisible(),

          // Edit profile
          Tap.on('edit_profile_button'),
          Type.into('name_field', 'Updated Name'),
          Tap.on('save_button'),
          Wait.until.widgetExists('success_message'),

          // Scroll and interact
          Scroll.down(amount: 200),
          Tap.on('settings_option'),
          Wait.for(Duration(milliseconds: 300)),

          // Final verification
          Assert.text('Updated Name').isVisible(),
        ],

        // Cleanup phase - reset state
        cleanup: [
          Tap.on('logout_button'),
          Wait.until.pageLoads<LoginPage>(),
        ],

        timeout: Duration(minutes: 2),
        metadata: {
          'test_type': 'integration',
          'priority': 'high',
          'tags': ['login', 'profile', 'navigation'],
        },
      );

      await TestPilotRunner.runSuite(tester, complexSuite);
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      TestPilot.initialize();

      final errorSuite = TestSuite(
        name: 'Error Handling Test',
        steps: [
          // This might fail - that's expected
          Assert.text('NonExistentText').isVisible(),
        ],
      );

      // Run but don't expect success
      await TestPilotRunner.runSuite(
        tester,
        errorSuite,
        expectSuccess: false,
      );

      // Verify we can continue after failure
      final recoverySuite = TestSuite(
        name: 'Recovery Test',
        steps: [
          Assert.text('Home').isVisible(), // This should pass
        ],
      );

      await TestPilotRunner.runSuite(tester, recoverySuite);
    });
  });

  group('Test Pilot Advanced Features', () {
    testWidgets('Parallel test groups', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      TestPilot.initialize();

      // You can run multiple groups in sequence
      final quickTests = TestGroup(
        name: 'Quick Smoke Tests',
        suites: [
          TestSuite(name: 'UI Visibility', steps: [
            Assert.text('Home').isVisible(),
            Assert.widget('menu_button').isVisible(),
          ]),
          TestSuite(name: 'Basic Navigation', steps: [
            Tap.on('about_button'),
            Navigate.back(),
          ]),
        ],
        stopOnFailure: false, // Continue even if one fails
      );

      final thoroughTests = TestGroup(
        name: 'Thorough Feature Tests',
        suites: [
          TestSuite(name: 'Form Interaction', steps: [
            Navigate.to('/contact'),
            Type.into('message_field', 'Test message'),
            Tap.on('send_button'),
            Wait.until.widgetExists('confirmation'),
          ]),
        ],
        stopOnFailure: true,
      );

      // Run both groups
      await TestPilotRunner.runGroup(tester, quickTests);
      await TestPilotRunner.runGroup(tester, thoroughTests);
    });
  });
}
*/
