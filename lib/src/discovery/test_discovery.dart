// test_discovery.dart - Auto-discovery system for Flutter apps
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auto-discovery system that analyzes Flutter apps to enable independent testing
class TestDiscovery {
  static final TestDiscovery _instance = TestDiscovery._();
  TestDiscovery._();

  static TestDiscovery get instance => _instance;

  final Map<String, WidgetInfo> _discoveredWidgets = {};
  final Map<String, RouteInfo> _discoveredRoutes = {};
  final List<String> _discoveredTexts = [];
  final List<String> _discoveredKeys = [];

  /// Discover all testable elements in the widget tree
  Future<DiscoveryResult> discoverApp(WidgetTester tester) async {
    _discoveredWidgets.clear();
    _discoveredRoutes.clear();
    _discoveredTexts.clear();
    _discoveredKeys.clear();

    await tester.pump();

    // Discover widgets
    _discoverWidgets(tester);

    // Discover text elements
    _discoverTexts(tester);

    // Discover keys
    _discoverKeys(tester);

    // Discover interactive elements
    _discoverInteractiveElements(tester);

    return DiscoveryResult(
      widgets: Map.from(_discoveredWidgets),
      routes: Map.from(_discoveredRoutes),
      texts: List.from(_discoveredTexts),
      keys: List.from(_discoveredKeys),
      timestamp: DateTime.now(),
    );
  }

  /// Discover all widgets in the tree
  void _discoverWidgets(WidgetTester tester) {
    final types = <Type>[
      // Buttons
      ElevatedButton,
      TextButton,
      OutlinedButton,
      IconButton,
      FloatingActionButton,

      // Input fields
      TextField,
      TextFormField,

      // Form elements
      Checkbox,
      Radio,
      Switch,
      Slider,
      DropdownButton,

      // Lists
      ListView,
      GridView,

      // Navigation
      AppBar,
      BottomNavigationBar,
      Drawer,
      TabBar,

      // Containers
      Card,
      Container,
      Scaffold,
    ];

    for (final type in types) {
      try {
        final finder = find.byType(type);
        final count = tester.widgetList(finder).length;

        if (count > 0) {
          _discoveredWidgets[type.toString()] = WidgetInfo(
            type: type,
            count: count,
            finder: finder,
          );
        }
      } catch (e) {
        // Widget type not found or not accessible
      }
    }
  }

  /// Discover all text elements
  void _discoverTexts(WidgetTester tester) {
    try {
      final textFinders = find.byType(Text);
      for (final element in tester.widgetList<Text>(textFinders)) {
        final data = element.data;
        if (data != null &&
            data.isNotEmpty &&
            !_discoveredTexts.contains(data)) {
          _discoveredTexts.add(data);
        }
      }
    } catch (e) {
      // No texts found
    }
  }

  /// Discover all keys
  void _discoverKeys(WidgetTester tester) {
    try {
      // This is a simplified version - in practice, we'd need to traverse the element tree
      final context = tester.element(find.byType(MaterialApp).first);
      _traverseForKeys(context);
    } catch (e) {
      // No keys found
    }
  }

  void _traverseForKeys(Element element) {
    final widget = element.widget;
    if (widget.key != null && widget.key is ValueKey) {
      final valueKey = widget.key as ValueKey;
      final keyString = valueKey.value.toString();
      if (!_discoveredKeys.contains(keyString)) {
        _discoveredKeys.add(keyString);
      }
    }
    element.visitChildren(_traverseForKeys);
  }

  /// Discover interactive elements (buttons, inputs, etc.)
  void _discoverInteractiveElements(WidgetTester tester) {
    // Find all tappable widgets
    final tappableTypes = [
      InkWell,
      GestureDetector,
      ElevatedButton,
      TextButton,
      IconButton,
    ];

    for (final type in tappableTypes) {
      try {
        final finder = find.byType(type);
        final count = tester.widgetList(finder).length;

        if (count > 0) {
          _discoveredWidgets['interactive_$type'] = WidgetInfo(
            type: type,
            count: count,
            finder: finder,
            isInteractive: true,
          );
        }
      } catch (e) {
        // Type not found
      }
    }
  }

  /// Find widget by text
  Finder? findByText(String text) {
    if (_discoveredTexts.contains(text)) {
      return find.text(text);
    }

    // Try partial match
    for (final discoveredText in _discoveredTexts) {
      if (discoveredText.toLowerCase().contains(text.toLowerCase())) {
        return find.text(discoveredText);
      }
    }

    return null;
  }

  /// Find widget by key
  Finder? findByKey(String key) {
    if (_discoveredKeys.contains(key)) {
      return find.byKey(ValueKey(key));
    }
    return null;
  }

  /// Get all interactive elements that can be tapped
  List<WidgetInfo> getInteractiveElements() {
    return _discoveredWidgets.values
        .where((info) => info.isInteractive)
        .toList();
  }

  /// Print discovery summary
  void printSummary(DiscoveryResult result) {
    print('\n🔍 App Discovery Summary');
    print('═' * 50);
    print('📊 Total Widgets: ${result.widgets.length}');
    print('📝 Total Texts: ${result.texts.length}');
    print('🔑 Total Keys: ${result.keys.length}');
    print(
      '🎯 Interactive Elements: ${result.widgets.values.where((w) => w.isInteractive).length}',
    );
    print('');

    if (result.widgets.isNotEmpty) {
      print('📦 Discovered Widgets:');
      result.widgets.forEach((name, info) {
        print(
          '  • $name: ${info.count} instance(s)${info.isInteractive ? " [Interactive]" : ""}',
        );
      });
    }

    if (result.texts.isNotEmpty) {
      print('\n📝 Discovered Texts (first 10):');
      result.texts.take(10).forEach((text) {
        final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
        print('  • "$preview"');
      });
      if (result.texts.length > 10) {
        print('  ... and ${result.texts.length - 10} more');
      }
    }

    if (result.keys.isNotEmpty) {
      print('\n🔑 Discovered Keys:');
      result.keys.forEach((key) {
        print('  • $key');
      });
    }

    print('═' * 50 + '\n');
  }
}

/// Widget information
class WidgetInfo {
  final Type type;
  final int count;
  final Finder finder;
  final bool isInteractive;

  WidgetInfo({
    required this.type,
    required this.count,
    required this.finder,
    this.isInteractive = false,
  });
}

/// Route information
class RouteInfo {
  final String name;
  final String? path;
  final Map<String, dynamic>? arguments;

  RouteInfo({required this.name, this.path, this.arguments});
}

/// Discovery result
class DiscoveryResult {
  final Map<String, WidgetInfo> widgets;
  final Map<String, RouteInfo> routes;
  final List<String> texts;
  final List<String> keys;
  final DateTime timestamp;

  DiscoveryResult({
    required this.widgets,
    required this.routes,
    required this.texts,
    required this.keys,
    required this.timestamp,
  });

  /// Export discovery to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'summary': {
        'totalWidgets': widgets.length,
        'totalTexts': texts.length,
        'totalKeys': keys.length,
        'interactiveElements': widgets.values
            .where((w) => w.isInteractive)
            .length,
      },
      'widgets': widgets.map(
        (key, value) => MapEntry(key, {
          'type': value.type.toString(),
          'count': value.count,
          'isInteractive': value.isInteractive,
        }),
      ),
      'texts': texts,
      'keys': keys,
    };
  }
}
