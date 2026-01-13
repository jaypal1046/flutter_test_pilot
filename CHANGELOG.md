# Changelog

All notable changes to Flutter Test Pilot will be documented in this file.  
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.8] - 2026-01-13

### Enhanced

- **Independent Operation**: The package now operates completely independently without requiring prior knowledge of your application's internal flow or structure
  - Works seamlessly with any Flutter application architecture
  - No need for manual setup or configuration of routes and navigation
  - Automatically discovers and interacts with UI elements using intelligent widget finding strategies
  
- **Live Data Integration Testing**: Verified and tested with real-world integration tests using live data
  - Integration test suite validates real application flows (navigation, user interactions, API calls)
  - Tested with actual Flutter apps including multi-page navigation scenarios
  - Proven reliability in production-like testing environments
  - Example integration tests demonstrate real-world use cases with HomePage, ClaimsPage, and ProfilePage navigation

### Improved

- Enhanced documentation explaining the framework's plug-and-play nature
- Added comprehensive integration test examples in the example app
- Improved test pilot navigator integration for seamless cross-page testing

## [1.0.7] - 2025-09-21

- Fix: Minor bug fixes and improvements



## [1.0.1] - 2025-09-21

- Addressed issues reported on pub.dev for this package:
  - Resolved code analysis warnings
  - Updated dependencies for compatibility
  - Improved documentation
  - Fixed concerns highlighted by pub.dev to enhance package quality and compliance

## [1.0.0] - 2025-09-21

### Added

#### Core Framework

- Initial release of **Flutter Test Pilot**, a robust testing framework for Flutter apps
- `FlutterTestPilot` singleton for streamlined test management
- `TestSuite` for organizing tests with setup, execution, and cleanup phases
- `TestGroup` for grouping related test suites
- `TestPilotRunner` for seamless `testWidgets` integration
- Comprehensive error handling and reporting

#### UI Interaction Actions

- **Tap Actions**: `Tap`, `DoubleTap`, `TripleTap`, `LongPress`
- **Text Input**: `Type` class with 17 widget-finding strategies
- **Drag Operations**: `DragDrop` with widget-to-widget and offset-based support
- **Gestures**: `Pan`, `Pinch`, `Scroll`, `Swipe`
- Smart widget disambiguation using context and position

#### API Testing

- `ApiObserverManager` for HTTP request/response interception
- `ApiTestAction` for API validation with `Api` factory (GET, POST, PUT, DELETE)
- `RequestCheck` and `ResponseCheck` for field-level validation
- JSON path navigation for complex API data
- Dio interceptor for automatic API capture

#### Widget Finding

- Key-based (ValueKey, Key, GlobalKey), text, widget type, and semantic label support
- Input decoration (hint, label, helper text) and controller-based finding
- Parent/child traversal and position-based selection

#### Reporting

- `ConsoleReporter` with colored, formatted output
- `JsonReporter` for structured results and JUnit XML for CI/CD
- Execution summaries with performance metrics

#### Validation

- Built-in functions (`exists`, `equals`, `contains`) and custom validation
- Detailed error messages with expected vs. actual comparisons

### Features

#### Error Handling

- Retry mechanisms for flaky UI interactions
- Custom error handlers and gesture boundary checks

#### Performance

- Optimized widget tree traversal and test execution
- Smart waiting for animations and state changes

#### Developer Experience

- Fluent, type-safe API with IDE-friendly intellisense
- Comprehensive documentation and example test suites

#### Test Organization

- Hierarchical structure: Groups > Suites > Steps
- Phase-based execution with metadata and timeout support

### Technical Details

#### Dependencies

- Flutter SDK: `>=3.0.0`
- Dart SDK: `>=2.17.0 <4.0.0`
- Dio: `^5.0.0` (for API testing)

#### Architecture

- Singleton for test management
- Observer pattern for API interception
- Strategy and factory patterns for widget finding and actions

#### Platform Support

- **Full**: iOS, Android
- **Partial**: Web (no native gestures), Desktop (limited gestures)

### Documentation

- README with quick start guide
- API reference and best practices
- Integration guides for popular packages

### Known Limitations

- Limited gesture support on web and desktop
- API testing requires Dio integration
- Some custom widgets may need advanced finding strategies

---

## Support and Compatibility

### Flutter Versions

- 3.0.x to 3.13.x: ✅ Fully Supported

### Dart Versions

- 2.17 to 3.1: ✅ Fully Supported

### Dependencies

| Package      | Version | Purpose                     |
| ------------ | ------- | --------------------------- |
| flutter      | SDK     | Core framework              |
| dio          | ^5.0.0  | HTTP client for API testing |
| flutter_test | SDK     | Test framework integration  |

---

## Migration Guide

As the initial 1.0.0 release, no migration is needed. Future versions will include detailed migration guides.

---

## Contributors

- Core development, UI interactions, API testing, reporting, and documentation

---

## License

Licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
