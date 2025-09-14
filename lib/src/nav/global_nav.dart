import 'package:flutter/material.dart';

/// TestPilotNavigator - Simple, reliable navigation manager
/// Works with any existing app setup without conflicts
class TestPilotNavigator {
  static GlobalKey<NavigatorState>? _activeKey;
  static bool _isConfigured = false;

  /// Use this when your app already has a navigator key
  /// (Most common scenario)
  static void useExistingKey(GlobalKey<NavigatorState> existingKey) {
    _activeKey = existingKey;
    _isConfigured = true;
    print('✅ Test Pilot: Using existing navigator key');
  }

  /// Use this for new apps or when you want Test Pilot to manage navigation
  static GlobalKey<NavigatorState> get ownKey {
    if (!_isConfigured) {
      _activeKey = _defaultKey;
      _isConfigured = true;
      print('✅ Test Pilot: Using own navigator key');
    }
    return _defaultKey;
  }

  /// Get the currently active navigator key
  static GlobalKey<NavigatorState> get navigatorKey {
    if (_activeKey == null) {
      throw TestPilotNavigatorException._notConfigured();
    }
    return _activeKey!;
  }

  /// Get the navigator state safely
  static NavigatorState get navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw TestPilotNavigatorException._notReady();
    }
    return state;
  }

  /// Check if navigator is ready for use
  static bool get isReady {
    try {
      return _activeKey != null && _activeKey!.currentState != null;
    } catch (e) {
      return false;
    }
  }

  // Navigation Methods
  static Future<void> pushTo(String routeName, {Object? arguments}) async {
    await navigator.pushNamed(routeName, arguments: arguments);
  }

  static Future<void> pushAndReplace(
    String routeName, {
    Object? arguments,
  }) async {
    await navigator.pushReplacementNamed(routeName, arguments: arguments);
  }

  static void pop([Object? result]) {
    navigator.pop(result);
  }

  static Future<void> pushToPage(Widget page) async {
    await navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  /// Navigate with built-in wait (useful for tests)
  static Future<void> navigateAndWait(
    String routeName, {
    Object? arguments,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    await pushTo(routeName, arguments: arguments);
    await Future.delayed(delay);
  }

  // Private members
  static final GlobalKey<NavigatorState> _defaultKey =
      GlobalKey<NavigatorState>();

  /// Reset configuration (useful for testing)
  static void reset() {
    _activeKey = null;
    _isConfigured = false;
  }

  /// Debug info
  static String get debugInfo {
    return '''
Test Pilot Navigator Status:
- Configured: $_isConfigured
- Has Active Key: ${_activeKey != null}
- Navigator Ready: $isReady
- Using Own Key: ${_activeKey == _defaultKey}
''';
  }
}

/// Custom exceptions for clear error messages
class TestPilotNavigatorException implements Exception {
  final String message;
  final String solution;

  TestPilotNavigatorException._(this.message, this.solution);

  factory TestPilotNavigatorException._notConfigured() {
    return TestPilotNavigatorException._(
      'TestPilotNavigator not configured',
      '''
Choose one solution:

1. If your app has existing navigator key:
   TestPilotNavigator.useExistingKey(MyApp.navigatorKey);

2. If you want Test Pilot to manage navigation:
   MaterialApp(navigatorKey: TestPilotNavigator.ownKey)

3. If using Alice or other tools:
   TestPilotNavigator.useExistingKey(Alice.navigatorKey);
      ''',
    );
  }

  factory TestPilotNavigatorException._notReady() {
    return TestPilotNavigatorException._('Navigator not ready', '''
Make sure:
1. MaterialApp is built and mounted
2. Navigator key is properly set
3. App initialization is complete

Current status: ${TestPilotNavigator.debugInfo}
      ''');
  }

  @override
  String toString() =>
      '''
🚨 $message

💡 $solution
''';
}
