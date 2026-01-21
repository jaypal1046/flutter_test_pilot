# Testing Guide for Flutter Test Pilot

## 📋 Overview

This guide provides comprehensive instructions for testing the Flutter Test Pilot framework.

## 🗂️ Test Structure

```
test/
├── unit/                          # Unit tests (organized by module)
│   ├── core/
│   │   └── cache_manager_test.dart
│   ├── executor/
│   │   ├── retry_handler_test.dart
│   │   └── parallel_executor_test.dart
│   └── discovery/
│       └── test_finder_test.dart
├── comprehensive_test.dart        # Manual comprehensive tests
├── flutter_test_pilot_test.dart   # Main library tests
└── flutter_test_pilot_method_channel_test.dart

example/integration_test/
└── comprehensive_app_test.dart    # Integration tests
```

## 🚀 Quick Start

### Run All Unit Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/unit/core/cache_manager_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### Run Integration Tests

```bash
cd example
flutter test integration_test/comprehensive_app_test.dart
```

## 🎯 Using the Test Runner Script

The `test_runner.sh` script provides an easy way to run different test suites:

### Run Only Unit Tests (Default)

```bash
./test_runner.sh
```

### Run All Tests

```bash
./test_runner.sh --all
```

### Run Only Integration Tests

```bash
./test_runner.sh --integration
```

### Run Comprehensive Manual Tests

```bash
./test_runner.sh --comprehensive
```

### Run with Coverage Report

```bash
./test_runner.sh --coverage
```

### Combinations

```bash
# Unit tests + Integration tests with coverage
./test_runner.sh --all --coverage

# Only comprehensive tests
./test_runner.sh --comprehensive
```

## 📊 Test Categories

### 1. Unit Tests (`test/unit/`)

**Fast, isolated tests** for individual components:

- **CacheManager Tests**: Cache operations, entry storage/retrieval
- **RetryHandler Tests**: Retry logic, error detection, backoff strategies
- **ParallelExecutor Tests**: Concurrent execution, device distribution
- **TestFinder Tests**: Test file discovery, metadata extraction

**Run with:**

```bash
flutter test test/unit/
```

### 2. Integration Tests (`example/integration_test/`)

**Full app flow tests** using the test_suite API:

- Form interactions
- Navigation flows
- API testing
- Gesture handling
- Wait conditions

**Prerequisites:**

- Connected device or running emulator
- Example app built

**Run with:**

```bash
cd example
flutter test integration_test/comprehensive_app_test.dart
```

### 3. Comprehensive Tests (`test/comprehensive_test.dart`)

**Manual validation tests** for native features:

- ADB Commander
- Permission Granter
- Dialog Watcher
- Native Handler
- Screenshot Capturer

**Prerequisites:**

- Android device connected (for device-specific tests)
- ADB installed and in PATH

**Run with:**

```bash
dart test/comprehensive_test.dart
```

## 🔍 Test Coverage

### Generate Coverage Report

```bash
# Generate coverage data
flutter test --coverage

# Install lcov (if not already installed)
# macOS:
brew install lcov
# Linux:
sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### View Coverage Summary

```bash
lcov --summary coverage/lcov.info
```

## 🎨 Writing New Tests

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YourClass', () {
    late YourClass instance;

    setUp(() {
      instance = YourClass();
    });

    tearDown(() {
      // Cleanup
    });

    test('should do something', () {
      // Arrange
      final input = 'test';

      // Act
      final result = instance.doSomething(input);

      // Assert
      expect(result, equals('expected'));
    });
  });
}
```

### Integration Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

void main() {
  testWidgets('should test feature', (WidgetTester tester) async {
    final testSuite = TestSuite(
      name: 'Feature Test',
      description: 'Testing a specific feature',
      steps: [
        TapAction.text('Button'),
        VerifyWidget(finder: find.text('Expected Text')),
        Wait.forDuration(Duration(seconds: 1)),
      ],
    );

    final results = await testSuite.execute(tester);
    expect(results.status, TestStatus.passed);
  });
}
```

## 📈 CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```

### GitLab CI Example

```yaml
test:
  image: cirrusci/flutter:stable
  script:
    - flutter pub get
    - flutter test --coverage
  coverage: '/lines\.*: \d+\.\d+\%/'
```

## 🐛 Debugging Tests

### Run Single Test

```bash
flutter test test/unit/core/cache_manager_test.dart --name "should save and retrieve"
```

### Run with Verbose Output

```bash
flutter test --verbose
```

### Run in Debug Mode

```bash
flutter test --start-paused
```

### VSCode Configuration

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Test",
      "type": "dart",
      "request": "launch",
      "program": "test/unit/core/cache_manager_test.dart"
    }
  ]
}
```

## ✅ Best Practices

1. **Keep tests fast**: Unit tests should run in milliseconds
2. **Isolate tests**: Use `setUp` and `tearDown` properly
3. **Use descriptive names**: Test names should explain what they test
4. **Follow AAA pattern**: Arrange, Act, Assert
5. **Mock external dependencies**: Don't rely on network or file system
6. **Test edge cases**: Include error scenarios
7. **Maintain test coverage**: Aim for 80%+ coverage

## 🔧 Troubleshooting

### Tests Failing Due to Cache

```bash
# Clear test cache
flutter clean
rm -rf build/
flutter pub get
```

### Integration Tests Timeout

```bash
# Increase timeout
flutter test integration_test/ --timeout=5m
```

### ADB Not Found

```bash
# Add ADB to PATH
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### Coverage Not Generated

```bash
# Ensure test package is available
flutter pub add --dev test
flutter test --coverage
```

## 📚 Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Test Package Documentation](https://pub.dev/packages/test)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [Mockito Package](https://pub.dev/packages/mockito)

## 🤝 Contributing Tests

When adding new features, please include:

1. Unit tests for business logic
2. Integration tests for UI flows (if applicable)
3. Update this README if new test patterns are introduced
4. Ensure all tests pass before submitting PR

```bash
# Before committing
./test_runner.sh --all
```
