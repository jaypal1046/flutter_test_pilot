# FlutterTestPilot Framework Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Components](#core-components)
4. [Installation & Setup](#installation--setup)
5. [Usage Guide](#usage-guide)
6. [API Reference](#api-reference)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Examples](#examples)

## Overview

FlutterTestPilot is a comprehensive integration testing framework for Flutter applications that provides:

- **Automatic test initialization** with proper binding setup
- **Independent test isolation** preventing test interference
- **Built-in navigation management** with TestPilotNavigator
- **Comprehensive test reporting** and statistics
- **Helper methods** for common testing scenarios
- **Multiple execution modes** for different testing needs

### Key Benefits

✅ **No more manual setup** - Framework handles all initialization automatically  
✅ **Reliable tests** - Each test runs in isolation with clean state  
✅ **Better debugging** - Detailed logging and error reporting  
✅ **Flexible architecture** - Works with any Flutter app structure  
✅ **Time-saving** - Reduced boilerplate code for tests  

---

## Architecture

```
FlutterTestPilot Framework
├── FlutterTestPilot (Main Class)
│   ├── Initialization & Configuration
│   ├── Test Execution Engine
│   ├── Result Management
│   └── Reporting System
│
├── TestPilotNavigator (Navigation Manager)
│   ├── Navigator Key Management
│   ├── Route Navigation
│   └── State Management
│
├── TestSuite (Test Definition)
│   ├── Setup Actions
│   ├── Test Steps
│   ├── Cleanup Actions
│   └── Execution Engine
│
└── Extensions & Helpers
    ├── WidgetTester Extensions
    ├── Wait Utilities
    └── Common Test Operations
```

---

## Core Components

### 1. FlutterTestPilot (Main Framework Class)

The central class that manages the entire testing lifecycle.

```dart
class FlutterTestPilot {
  // Core functionality
  static void initialize({...});           // Framework setup
  static Future<TestResult> runTest({...}); // Single test execution
  static Future<List<TestResult>> runTestSuite({...}); // Multiple tests
  static Future<TestResult> quickTest({...}); // Simple test scenarios
}
```

**Responsibilities:**
- Integration test binding initialization
- Global setup and cleanup management  
- Test isolation and state management
- Result collection and reporting

### 2. TestPilotNavigator (Navigation Manager)

Handles all navigation-related operations with flexible configuration.

```dart
class TestPilotNavigator {
  // Configuration methods
  static void useExistingKey(GlobalKey<NavigatorState> existingKey);
  static GlobalKey<NavigatorState> get ownKey;
  
  // Navigation methods
  static Future<void> pushTo(String routeName, {Object? arguments});
  static Future<void> pushAndReplace(String routeName, {Object? arguments});
  static void pop([Object? result]);
}
```

**Key Features:**
- Works with existing app navigator keys
- Can manage its own navigator key
- Provides safe navigation with error handling
- Built-in wait functionality for stable tests

### 3. TestSuite (Test Definition Structure)

Defines complete test scenarios with setup, execution, and cleanup phases.

```dart
class TestSuite {
  final String name;
  final List<TestAction> setup;    // Pre-test actions
  final List<TestAction> steps;    // Main test actions  
  final List<TestAction> cleanup;  // Post-test actions
  
  Future<TestResult> execute(WidgetTester tester);
}
```

### 4. Helper Extensions

Convenient methods for common testing operations.

```dart
extension TestPilotExtensions on WidgetTester {
  Future<void> tapAndSettle(Finder finder);
  Future<void> enterTextAndSettle(Finder finder, String text);
  Future<void> navigateAndWait(String routeName, {Object? arguments});
}
```

---

## Installation & Setup

### 1. Add Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  # Add your TestPilot files to lib/ or test/ folder
```

### 2. File Structure

```
your_flutter_project/
├── lib/
│   └── main.dart
├── test/
│   ├── test_pilot/
│   │   ├── flutter_test_pilot.dart
│   │   ├── global_nav.dart
│   │   ├── test_suite.dart
│   │   ├── test_action.dart
│   │   ├── test_result.dart
│   │   └── step_result.dart
│   └── widget_test.dart
└── integration_test/
    └── app_test.dart
```

### 3. Basic Integration

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart';

import '../test/test_pilot/flutter_test_pilot.dart';

void main() {
  // Initialize the framework
  setUpAll(() {
    FlutterTestPilot.initialize(
      navigatorKey: MyApp.navigatorKey, // Your app's navigator key
      globalSetup: () async {
        print('🔧 Global test setup');
        // Initialize test databases, mock services, etc.
      },
      globalCleanup: () async {
        print('🧹 Global test cleanup');
        // Clean up test data, reset services, etc.
      },
    );
  });

  // Your tests go here...
}
```

---

## Usage Guide

### Initialization Patterns

#### Pattern 1: Using Existing Navigator Key (Recommended)

```dart
class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Your existing key
      // ... rest of app config
    );
  }
}

// In tests:
FlutterTestPilot.initialize(
  navigatorKey: MyApp.navigatorKey, // Use existing key
);
```

#### Pattern 2: Let TestPilot Manage Navigation

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: TestPilotNavigator.ownKey, // TestPilot's key
      // ... rest of app config
    );
  }
}

// In tests:
FlutterTestPilot.initialize(); // No navigator key needed
```

#### Pattern 3: Integration with Other Tools (e.g., Alice)

```dart
// If you're using Alice or similar tools
FlutterTestPilot.initialize(
  navigatorKey: alice.getNavigatorKey(),
);
```

### Test Execution Modes

#### Mode 1: TestSuite-Based Testing (Structured)

```dart
// Define a complete test scenario
final loginTest = TestSuite(
  name: 'User Login Flow',
  description: 'Complete login process from start to finish',
  
  setup: [
    // Actions to run before main test
    ClearUserData(),
    SetupMockServer(),
  ],
  
  steps: [
    // Main test actions
    NavigateTo('/login'),
    EnterText('email_field', 'test@example.com'),
    EnterText('password_field', 'password123'),
    TapButton('login_button'),
    WaitForPage<HomePage>(),
    VerifyText('Welcome back!'),
  ],
  
  cleanup: [
    // Actions to run after test
    Logout(),
    ClearCache(),
  ],
);

// Execute the test
testWidgets('should complete login flow', (WidgetTester tester) async {
  final result = await FlutterTestPilot.runTest(
    'Login Flow Test',
    loginTest,
    MyApp(),
    isolateTest: true, // Each test runs independently
  );
  
  expect(result.status, TestStatus.passed);
});
```

#### Mode 2: Quick Testing (Simple)

```dart
testWidgets('should display home screen', (WidgetTester tester) async {
  await FlutterTestPilot.quickTest(
    'Home Screen Test',
    MyApp(),
    (tester) async {
      // Simple test logic
      expect(find.text('Welcome'), findsOneWidget);
      
      // Use helper methods
      await tester.tapAndSettle(find.text('Profile'));
      await FlutterTestPilot.waitForPage<ProfilePage>(tester);
      
      expect(find.text('Profile'), findsOneWidget);
    },
  );
});
```

#### Mode 3: Batch Testing (Multiple Suites)

```dart
final testSuites = {
  'Registration Flow': registrationTestSuite,
  'Login Flow': loginTestSuite,
  'Profile Update': profileTestSuite,
  'Settings Navigation': settingsTestSuite,
};

testWidgets('should run all user flows', (WidgetTester tester) async {
  final results = await FlutterTestPilot.runTestSuite(
    testSuites,
    MyApp(),
    isolateTests: true, // Each suite runs independently
  );
  
  // Verify all tests passed
  for (final result in results) {
    expect(result.status, TestStatus.passed);
  }
});
```

---

## API Reference

### FlutterTestPilot Methods

#### `initialize({...})`
Initializes the testing framework. Call once at the beginning of your test suite.

```dart
static void initialize({
  GlobalKey<NavigatorState>? navigatorKey,  // Optional: your app's navigator key
  Function()? globalSetup,                  // Optional: global setup function
  Function()? globalCleanup,               // Optional: global cleanup function
})
```

**Parameters:**
- `navigatorKey`: Your app's existing navigator key (optional)
- `globalSetup`: Function to run before all tests (optional)
- `globalCleanup`: Function to run after all tests (optional)

#### `runTest({...})`
Executes a single test suite with full lifecycle management.

```dart
static Future<TestResult> runTest(
  String testName,              // Name of the test
  TestSuite testSuite,          // Test suite to execute
  Widget app,                   // Your app widget
  {
    bool isolateTest = true,    // Whether to isolate this test
    Duration? timeout,          // Optional timeout
  }
)
```

**Process:**
1. Runs global setup (if configured)
2. Pumps your app widget
3. Waits for screen to settle
4. Verifies navigator is ready
5. Executes test suite (setup → steps → cleanup)
6. Collects results and logs
7. Runs global cleanup (if configured)
8. Resets state (if isolateTest = true)

#### `runTestSuite({...})`
Executes multiple test suites in sequence.

```dart
static Future<List<TestResult>> runTestSuite(
  Map<String, TestSuite> testSuites,  // Map of test name to test suite
  Widget app,                         // Your app widget
  {
    bool isolateTests = true,         // Whether to isolate each test
    Duration? globalTimeout,          // Optional global timeout
  }
)
```

#### `quickTest({...})`
Simple test execution for basic scenarios.

```dart
static Future<TestResult> quickTest(
  String testName,                              // Test name
  Widget app,                                   // Your app widget
  Future<void> Function(WidgetTester) testFunction, // Test function
  {
    Function()? setup,                          // Optional setup
    Function()? cleanup,                        // Optional cleanup
  }
)
```

### Helper Methods

#### `waitForWidget({...})`
Waits for a specific widget to appear on screen.

```dart
static Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder,
  {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }
)
```

#### `waitForPage<T>({...})`
Waits for a specific page/widget type to load.

```dart
static Future<void> waitForPage<T>(
  WidgetTester tester,
  {Duration timeout = const Duration(seconds: 10)}
)

// Usage:
await FlutterTestPilot.waitForPage<HomePage>(tester);
```

### TestPilotNavigator Methods

#### Navigation Methods

```dart
// Navigate to named route
static Future<void> pushTo(String routeName, {Object? arguments});

// Navigate and replace current route
static Future<void> pushAndReplace(String routeName, {Object? arguments});

// Go back
static void pop([Object? result]);

// Navigate to widget directly
static Future<void> pushToPage(Widget page);

// Navigate with built-in wait
static Future<void> navigateAndWait(
  String routeName,
  {Object? arguments, Duration delay = const Duration(milliseconds: 500)}
);
```

#### State Management

```dart
// Check if navigator is ready
static bool get isReady;

// Get current navigator state
static NavigatorState get navigator;

// Reset navigator configuration
static void reset();

// Get debug information
static String get debugInfo;
```

### Extension Methods

#### WidgetTester Extensions

```dart
// Tap and wait for animations to settle
Future<void> tapAndSettle(Finder finder);

// Enter text and wait for animations to settle  
Future<void> enterTextAndSettle(Finder finder, String text);

// Scroll and wait for animations to settle
Future<void> scrollAndSettle(Finder finder, Offset offset);

// Navigate and wait for completion
Future<void> navigateAndWait(String routeName, {Object? arguments});
```

---

## Best Practices

### 1. Test Structure Organization

```dart
void main() {
  // ✅ Initialize once at the top
  setUpAll(() {
    FlutterTestPilot.initialize(/*...*/);
  });

  // ✅ Group related tests
  group('Authentication Tests', () {
    // Login tests
  });

  group('User Profile Tests', () {
    // Profile tests
  });

  // ✅ Clean up at the end
  tearDownAll(() {
    FlutterTestPilot.reset();
  });
}
```

### 2. Test Isolation

```dart
// ✅ Always use test isolation for integration tests
await FlutterTestPilot.runTest(
  'My Test',
  testSuite,
  MyApp(),
  isolateTest: true, // This ensures clean state
);

// ✅ Use separate test suites for different features
final authTests = {'login': loginSuite, 'register': registerSuite};
final profileTests = {'update': updateSuite, 'delete': deleteSuite};
```

### 3. Error Handling

```dart
// ✅ Always check test results
final result = await FlutterTestPilot.runTest(/*...*/);
expect(result.status, TestStatus.passed);

if (result.error != null) {
  print('Test failed: ${result.error}');
}

// ✅ Use try-catch for cleanup
try {
  await FlutterTestPilot.runTest(/*...*/);
} catch (e) {
  print('Test execution failed: $e');
  // Handle failure
}
```

### 4. Navigation Best Practices

```dart
// ✅ Wait for navigation to complete
await tester.navigateAndWait('/profile');

// ✅ Verify navigation succeeded
await FlutterTestPilot.waitForPage<ProfilePage>(tester);
expect(find.byType(ProfilePage), findsOneWidget);

// ✅ Use named routes instead of direct widget navigation
await TestPilotNavigator.pushTo('/settings');
// Instead of: TestPilotNavigator.pushToPage(SettingsPage());
```

### 5. Timing and Waits

```dart
// ✅ Use framework's built-in waits
await FlutterTestPilot.waitForWidget(tester, find.text('Loading complete'));

// ✅ Always pump and settle after actions
await tester.tapAndSettle(find.text('Submit'));

// ❌ Avoid arbitrary delays
// await Future.delayed(Duration(seconds: 2)); // Don't do this

// ✅ Use specific wait conditions
await FlutterTestPilot.waitForPage<HomePage>(tester);
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. "TestPilot not initialized" Error

**Problem:** Forgetting to call `FlutterTestPilot.initialize()`

**Solution:**
```dart
setUpAll(() {
  FlutterTestPilot.initialize(); // Add this
});
```

#### 2. "Navigator not ready" Error

**Problem:** Navigator key not properly configured

**Solutions:**
```dart
// Option 1: Use existing key
FlutterTestPilot.initialize(navigatorKey: MyApp.navigatorKey);

// Option 2: Use TestPilot's key
MaterialApp(navigatorKey: TestPilotNavigator.ownKey)

// Option 3: Check navigator status
if (!TestPilotNavigator.isReady) {
  await tester.pumpAndSettle(); // Wait for app initialization
}
```

#### 3. Tests Interfering with Each Other

**Problem:** Previous test state affecting current test

**Solution:**
```dart
// Enable test isolation
await FlutterTestPilot.runTest(
  'My Test',
  testSuite,
  MyApp(),
  isolateTest: true, // This fixes the issue
);
```

#### 4. Widget Not Found Errors

**Problem:** Trying to interact with widgets before they're ready

**Solution:**
```dart
// Wait for widget to appear
await FlutterTestPilot.waitForWidget(tester, find.text('My Widget'));

// Or wait for page to load
await FlutterTestPilot.waitForPage<MyPage>(tester);

// Then interact with it
await tester.tapAndSettle(find.text('My Widget'));
```

#### 5. Timeout Issues

**Problem:** Tests timing out waiting for conditions

**Solutions:**
```dart
// Increase timeout for slow operations
await FlutterTestPilot.waitForWidget(
  tester,
  find.text('Slow Loading Widget'),
  timeout: Duration(seconds: 30), // Increased timeout
);

// Set global timeout for test suite
await FlutterTestPilot.runTest(
  'Slow Test',
  testSuite,
  MyApp(),
  timeout: Duration(minutes: 5), // Global timeout
);
```

### Debug Information

```dart
// Get framework status
print(TestPilotNavigator.debugInfo);

// Get test statistics
final stats = FlutterTestPilot.statistics;
print('Passed: ${stats['passed']}, Failed: ${stats['failed']}');

// Get test results
final results = FlutterTestPilot.testResults;
for (final result in results) {
  print('${result.suiteName}: ${result.status}');
}
```

---

## Examples

### Example 1: Complete Login Flow

```dart
void main() {
  setUpAll(() {
    FlutterTestPilot.initialize(
      navigatorKey: MyApp.navigatorKey,
      globalSetup: () async {
        // Setup test environment
        await TestDatabase.initialize();
        await MockApiServer.start();
      },
      globalCleanup: () async {
        // Cleanup test environment
        await TestDatabase.clear();
        await MockApiServer.stop();
      },
    );
  });

  group('Authentication Flow', () {
    final loginTest = TestSuite(
      name: 'Complete Login Process',
      description: 'Test full login flow with validation',
      
      setup: [
        ClearUserSession(),
        NavigateToLogin(),
      ],
      
      steps: [
        // Enter credentials
        EnterText('email_field', 'test@example.com'),
        EnterText('password_field', 'correct_password'),
        
        // Submit form
        TapButton('login_submit'),
        
        // Wait for API response
        WaitForApiCall('/api/login'),
        
        // Verify successful login
        WaitForPage<HomePage>(),
        VerifyText('Welcome back, Test User!'),
        VerifyVisible('logout_button'),
        
        // Verify navigation state
        AssertCurrentRoute('/home'),
      ],
      
      cleanup: [
        Logout(),
        ClearCache(),
      ],
    );

    testWidgets('should complete login successfully', (WidgetTester tester) async {
      final result = await FlutterTestPilot.runTest(
        'Login Flow Test',
        loginTest,
        MyApp(),
        isolateTest: true,
        timeout: Duration(seconds: 30),
      );
      
      expect(result.status, TestStatus.passed);
      expect(result.error, isNull);
    });
  });
}
```

### Example 2: E-commerce Shopping Flow

```dart
group('Shopping Cart Tests', () {
  final shoppingTest = TestSuite(
    name: 'Add to Cart and Checkout',
    
    steps: [
      // Browse products
      NavigateTo('/products'),
      WaitForPage<ProductListPage>(),
      
      // Select product
      TapWidget('product_card_1'),
      WaitForPage<ProductDetailPage>(),
      VerifyText('Product Details'),
      
      // Add to cart
      TapButton('add_to_cart'),
      WaitForSnackbar('Added to cart'),
      
      // Go to cart
      TapButton('cart_icon'),
      WaitForPage<CartPage>(),
      
      // Verify item in cart
      VerifyText('1 item'),
      VerifyVisible('checkout_button'),
      
      // Proceed to checkout
      TapButton('checkout_button'),
      WaitForPage<CheckoutPage>(),
      
      // Fill checkout form
      EnterText('address_field', '123 Test Street'),
      EnterText('city_field', 'Test City'),
      SelectDropdown('payment_method', 'Credit Card'),
      
      // Complete purchase
      TapButton('place_order'),
      WaitForPage<OrderConfirmationPage>(),
      VerifyText('Order confirmed'),
    ],
  );

  testWidgets('should complete shopping flow', (WidgetTester tester) async {
    await FlutterTestPilot.runTest('Shopping Flow', shoppingTest, MyApp());
  });
});
```

### Example 3: Form Validation Testing

```dart
testWidgets('should validate form fields correctly', (WidgetTester tester) async {
  await FlutterTestPilot.quickTest(
    'Form Validation Test',
    MyApp(),
    (tester) async {
      // Navigate to form
      await tester.navigateAndWait('/register');
      
      // Test empty field validation
      await tester.tapAndSettle(find.text('Submit'));
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      
      // Test invalid email
      await tester.enterTextAndSettle(find.byKey(Key('email_field')), 'invalid-email');
      await tester.tapAndSettle(find.text('Submit'));
      expect(find.text('Invalid email format'), findsOneWidget);
      
      // Test short password
      await tester.enterTextAndSettle(find.byKey(Key('password_field')), '123');
      await tester.tapAndSettle(find.text('Submit'));
      expect(find.text('Password too short'), findsOneWidget);
      
      // Test valid form
      await tester.enterTextAndSettle(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterTextAndSettle(find.byKey(Key('password_field')), 'validpassword123');
      await tester.tapAndSettle(find.text('Submit'));
      
      // Should proceed to next screen
      await FlutterTestPilot.waitForPage<SuccessPage>(tester);
      expect(find.text('Registration successful'), findsOneWidget);
    },
  );
});
```

This comprehensive documentation provides everything needed to understand and effectively use the FlutterTestPilot framework for robust integration testing in Flutter applications.