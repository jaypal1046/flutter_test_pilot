# Flutter Test Pilot

A comprehensive, fluent testing framework for Flutter applications that makes UI testing intuitive and maintainable.

[![pub package](https://img.shields.io/pub/v/flutter_test_pilot.svg)](https://pub.dev/packages/flutter_test_pilot)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Fluent API**: Write tests that read like natural language
- **Comprehensive UI Interactions**: Tap, type, drag, swipe, scroll, pinch, and pan gestures
- **Smart Widget Finding**: Multiple strategies for finding UI elements
- **API Testing**: Intercept and validate HTTP requests/responses
- **Rich Reporting**: Console and JSON output with detailed test results
- **Test Suites**: Organize tests with setup, main steps, and cleanup phases
- **Error Handling**: Robust error handling with retry mechanisms

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dev_dependencies:
  flutter_test_pilot: ^1.0.0
  flutter_test: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize Test Pilot

```dart
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  testWidgets('Login flow test', (WidgetTester tester) async {
    // Initialize your app
    await tester.pumpWidget(MyApp());
    
    // Create and run test suite
    final loginSuite = TestSuite(
      name: 'User Login Flow',
      steps: [
        Type.hint('Email').text('user@example.com'),
        Type.hint('Password').text('password123'),
        Tap.text('Login'),
        // Add API validation
        Api.post(
          id: 'login-api',
          urlPattern: r'/api/auth/login',
          expectedStatus: 200,
          responseChecks: [
            ResponseCheck('token', exists()),
            ResponseCheck('user.id', isNotEmpty()),
          ],
        ),
      ],
    );

    await TestPilotRunner.runSuite(tester, loginSuite);
  });
}
```

### 2. UI Interactions

#### Tapping

```dart
// Tap by text
Tap.text('Submit')

// Tap by key
Tap.key('submit_button')

// Double tap
DoubleTap.text('Item')

// Long press
LongPress.widget('Menu Item')

// Disambiguate multiple elements
Tap.text('Submit').inContext('Login Form')
Tap.text('Delete').atPosition('first')
```

#### Text Input

```dart
// Type by hint text
Type.hint('Email').text('user@example.com')

// Type by label
Type.label('Full Name').text('John Doe')

// Type by key
Type.key('password_field').text('secret123')

// Clear and type
Type.hint('Search').clearAndType('flutter')

// Append to existing text
Type.hint('Notes').append(' - Additional info')
```

#### Gestures

```dart
// Drag and drop
DragDrop.fromTo(
  fromText: 'Item 1',
  toText: 'Drop Zone'
)

// Swipe to dismiss
Swipe.toDismiss(itemText: 'Notification')

// Scroll until visible
Scroll.untilVisible('Bottom Item')

// Pinch to zoom
Pinch.zoomIn(scale: 2.0, onType: InteractiveViewer)

// Pan in direction
Pan.inDirection(direction: PanDirection.left, distance: 100)
```

### 3. Test Suites and Organization

```dart
final comprehensive_test = TestSuite(
  name: 'User Registration',
  description: 'Complete user registration flow with validation',
  
  // Setup phase
  setup: [
    Tap.text('Get Started'),
    // Navigate to registration
  ],
  
  // Main test steps
  steps: [
    Type.hint('First Name').text('John'),
    Type.hint('Last Name').text('Doe'), 
    Type.hint('Email').text('john.doe@example.com'),
    Type.hint('Password').text('securePassword123'),
    Tap.text('Register'),
  ],
  
  // API validations
  apis: [
    Api.post(
      id: 'register-user',
      urlPattern: r'/api/users/register',
      expectedStatus: 201,
      requestChecks: [
        RequestCheck('email', isEmail()),
        RequestCheck('firstName', isNotEmpty()),
      ],
      responseChecks: [
        ResponseCheck('user.id', exists()),
        ResponseCheck('message', contains('success')),
      ],
    ),
  ],
  
  // Cleanup phase
  cleanup: [
    // Logout or reset state if needed
  ],
);
```

### 4. Test Groups

```dart
final testGroup = TestGroup(
  name: 'Authentication Tests',
  description: 'Complete authentication flow testing',
  suites: [
    loginTestSuite,
    registrationTestSuite,
    forgotPasswordTestSuite,
  ],
  stopOnFailure: true,
);

// Run the entire group
await TestPilotRunner.runGroup(tester, testGroup);
```

### 5. API Testing

#### Setup API Interception

```dart
// In your main.dart or test setup
void main() {
  final dio = Dio();
  ApiObserverManager.initialize(dio); // Initialize API observation
  
  runApp(MyApp(dio: dio));
}
```

#### API Validation Examples

```dart
// Basic API test
Api.get(
  id: 'fetch-profile',
  urlPattern: r'/api/user/profile',
  responseChecks: [
    ResponseCheck('name', isNotEmpty()),
    ResponseCheck('email', isEmail()),
    ResponseCheck('age', isGreaterThan(0)),
  ],
)

// Complex request validation
Api.post(
  id: 'create-order',
  urlPattern: r'/api/orders',
  requestChecks: [
    RequestCheck('items', isNotEmpty()),
    RequestCheck('items[0].quantity', isGreaterThan(0)),
    RequestCheck('total', isNumber()),
  ],
  responseChecks: [
    ResponseCheck('orderId', exists()),
    ResponseCheck('status', equals('pending')),
  ],
)
```

### 6. Reporting

#### Console Output

```dart
final consoleReporter = ConsoleReporter(
  showDetails: true,
  showTimings: true,
  useColors: true,
);

// Report individual test
consoleReporter.reportTest(testResult);

// Report group results  
consoleReporter.reportGroup('Auth Tests', results);
```

#### JSON Reports

```dart
final jsonReporter = JsonReporter(
  prettyPrint: true,
  outputFile: 'test_results.json',
);

// Generate comprehensive report
final report = jsonReporter.generateExecutionReport(
  allResults,
  environment: {
    'platform': 'iOS',
    'version': '16.0',
    'device': 'iPhone 14'
  },
);

await jsonReporter.outputReport(report);
```

## Advanced Features

### Smart Widget Finding

The framework uses multiple strategies to find widgets:

- By key (ValueKey, Key, GlobalKey)
- By text content
- By widget type
- By semantic labels
- By decoration properties (hint, label, helper text)
- By position and index
- By parent/child relationships
- By controller and focus node properties

### Error Handling and Retries

```dart
Pan.inDirection(
  direction: PanDirection.left,
  distance: 100,
  maxRetries: 3,
  onError: (e) => print('Pan failed: $e'),
  waitForAnimation: true,
)
```

### Context and Disambiguation

```dart
// When multiple widgets match, use context
Tap.text('Submit')
  .inContext('Payment Form')
  .withRetry(maxAttempts: 2)

// Or specify position
Type.hint('Search')
  .atPosition('first')
  .clearAndType('flutter')
```

### Custom Validations

```dart
// Create custom validation functions
ValidationFunction isValidPrice() {
  return (field, value) async {
    if (value is num && value > 0) {
      return ApiValidationResult.success(field, 'Valid price', value: value);
    }
    return ApiValidationResult.failure(field, 'Invalid price', actual: value);
  };
}

// Use in API tests
ResponseCheck('price', isValidPrice())
```

## Best Practices

### 1. Organize Tests Logically

```dart
// Group related functionality
final userManagementTests = TestGroup(
  name: 'User Management',
  suites: [
    profileUpdateSuite,
    passwordChangeSuite,
    accountDeletionSuite,
  ],
);
```

### 2. Use Meaningful Test Names

```dart
TestSuite(
  name: 'Checkout - Payment Processing with Credit Card',
  description: 'Validates complete payment flow including validation errors',
  // ...
);
```

### 3. Validate Both UI and APIs

```dart
steps: [
  Type.hint('Amount').text('100.00'),
  Tap.text('Pay Now'),
  
  // Wait for UI feedback
  WaitFor.text('Payment Successful', timeout: Duration(seconds: 5)),
],
apis: [
  Api.post(
    id: 'process-payment',
    urlPattern: r'/api/payments',
    expectedStatus: 200,
    responseChecks: [
      ResponseCheck('transactionId', exists()),
      ResponseCheck('status', equals('completed')),
    ],
  ),
],
```

### 4. Handle Loading States

```dart
steps: [
  Tap.text('Load Data'),
  WaitFor.text('Loading...', timeout: Duration(seconds: 2)),
  WaitFor.textDisappears('Loading...', timeout: Duration(seconds: 10)),
  Assert.textExists('Data loaded successfully'),
],
```

## API Reference

### Core Classes

- `FlutterTestPilot`: Main entry point and singleton manager
- `TestSuite`: Container for organized test steps
- `TestGroup`: Collection of test suites
- `TestResult`: Results and metrics from test execution

### UI Actions

- `Tap`, `DoubleTap`, `TripleTap`, `LongPress`: Touch interactions
- `Type`: Text input with smart field detection
- `DragDrop`: Drag and drop operations
- `Swipe`: Swipe gestures in all directions
- `Scroll`: Scrolling with position control
- `Pan`: Pan gestures with momentum
- `Pinch`: Pinch-to-zoom operations

### API Testing

- `Api`: Factory for creating API tests
- `RequestCheck`, `ResponseCheck`: Field validation
- `ApiObserverManager`: HTTP interception and validation

### Reporting

- `ConsoleReporter`: Rich console output with colors
- `JsonReporter`: Structured JSON reports for CI/CD

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and updates.