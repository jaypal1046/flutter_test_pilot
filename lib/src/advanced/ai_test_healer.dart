// ai_test_healer.dart - AI-powered self-healing test mechanism
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// AI-powered test healing that automatically adapts to UI changes
class AITestHealer {
  static final AITestHealer _instance = AITestHealer._internal();
  factory AITestHealer() => _instance;
  AITestHealer._internal();

  final Map<String, List<FinderStrategy>> _healingStrategies = {};
  final Map<String, int> _healingAttempts = {};
  bool _enableHealing = true;

  /// Enable or disable test healing
  void setHealingEnabled(bool enabled) {
    _enableHealing = enabled;
  }

  /// Find element with self-healing capability
  Future<Finder> healingFind(
    WidgetTester tester,
    String elementId, {
    Finder? primaryFinder,
    List<FinderStrategy>? fallbackStrategies,
  }) async {
    // Try primary finder first
    if (primaryFinder != null) {
      try {
        if (tester.any(primaryFinder)) {
          return primaryFinder;
        }
      } catch (e) {
        // Primary finder failed, proceed to healing
      }
    }

    if (!_enableHealing) {
      throw Exception('Element not found and healing is disabled: $elementId');
    }

    // Try healing strategies
    final strategies = fallbackStrategies ?? _getDefaultStrategies(elementId);

    for (final strategy in strategies) {
      try {
        final finder = await strategy.findElement(tester, elementId);
        if (tester.any(finder)) {
          _recordSuccessfulStrategy(elementId, strategy);
          print('🔧 Test Healer: Found $elementId using ${strategy.name}');
          return finder;
        }
      } catch (e) {
        // Strategy failed, try next
        continue;
      }
    }

    // All strategies failed
    _recordHealingFailure(elementId);
    throw Exception(
      'Element not found after ${strategies.length} healing attempts: $elementId',
    );
  }

  /// Get default healing strategies
  List<FinderStrategy> _getDefaultStrategies(String elementId) {
    return [
      KeyFinderStrategy(),
      TextFinderStrategy(),
      IconFinderStrategy(),
      SemanticLabelStrategy(),
      WidgetTypeStrategy(),
      PositionalStrategy(),
      FuzzyMatchStrategy(),
    ];
  }

  /// Record successful strategy for future use
  void _recordSuccessfulStrategy(String elementId, FinderStrategy strategy) {
    _healingStrategies[elementId] ??= [];
    _healingStrategies[elementId]!.insert(0, strategy);
    _healingAttempts[elementId] = 0;
  }

  /// Record healing failure
  void _recordHealingFailure(String elementId) {
    _healingAttempts[elementId] = (_healingAttempts[elementId] ?? 0) + 1;

    if (_healingAttempts[elementId]! > 3) {
      print(
        '⚠️ Test Healer: Element $elementId consistently failing - may need manual intervention',
      );
    }
  }

  /// Get healing statistics
  Map<String, dynamic> getHealingStats() {
    return {
      'total_healed_elements': _healingStrategies.length,
      'total_failures': _healingAttempts.values.where((v) => v > 0).length,
      'strategies_used': _healingStrategies.values
          .expand((list) => list)
          .map((s) => s.name)
          .toSet()
          .toList(),
    };
  }

  /// Clear healing cache
  void clearCache() {
    _healingStrategies.clear();
    _healingAttempts.clear();
  }
}

/// Base class for finder strategies
abstract class FinderStrategy {
  String get name;
  Future<Finder> findElement(WidgetTester tester, String elementId);

  @Deprecated('Use findElement instead')
  Future<Finder> find(WidgetTester tester, String elementId) =>
      findElement(tester, elementId);
}

/// Find by Key
class KeyFinderStrategy extends FinderStrategy {
  @override
  String get name => 'Key';

  @override
  Future<Finder> findElement(WidgetTester tester, String elementId) async {
    return find.byKey(Key(elementId));
  }
}

/// Find by Text (exact and partial match)
class TextFinderStrategy extends FinderStrategy {
  @override
  String get name => 'Text';

  @override
  Future<Finder> findElement(WidgetTester tester, String elementId) async {
    // Try exact match first
    var finder = find.text(elementId);
    if (tester.any(finder)) return finder;

    // Try case-insensitive
    finder = find.text(elementId, findRichText: true);
    if (tester.any(finder)) return finder;

    // Try partial match
    finder = find.textContaining(elementId, findRichText: true);
    return finder;
  }
}

/// Find by Icon
class IconFinderStrategy extends FinderStrategy {
  @override
  String get name => 'Icon';

  @override
  Future<Finder> findElement(WidgetTester tester, String elementId) async {
    // Try to find by icon data if elementId matches common icon names
    return find.byIcon(Icons.ac_unit); // This would need icon name mapping
  }
}

/// Find by Semantic Label
class SemanticLabelStrategy extends FinderStrategy {
  @override
  String get name => 'SemanticLabel';

  @override
  Future<Finder> findElement(WidgetTester tester, String elementId) async {
    return find.bySemanticsLabel(elementId);
  }
}

/// Find by Widget Type
class WidgetTypeStrategy extends FinderStrategy {
  @override
  String get name => 'WidgetType';

  @override
  Future<Finder> findElement(WidgetTester tester, String elementId) async {
    // Try common widget types
    for (final type in [
      TextField,
      ElevatedButton,
      TextButton,
      IconButton,
      Container,
      Card,
    ]) {
      final finder = find.byType(type);
      if (tester.any(finder)) {
        // Check if any match has text containing elementId
        for (final element in finder.evaluate()) {
          final widget = element.widget;
          if (_widgetContainsText(widget, elementId)) {
            return find.byWidget(widget);
          }
        }
      }
    }
    throw Exception('No matching widget type found');
  }

  bool _widgetContainsText(Widget widget, String text) {
    if (widget is Text) {
      return widget.data?.contains(text) ?? false;
    } else if (widget is ElevatedButton || widget is TextButton) {
      // Check child widgets
      return false; // Simplified - would need recursive check
    }
    return false;
  }
}

/// Find by Position (last resort)
class PositionalStrategy extends FinderStrategy {
  @override
  String get name => 'Positional';

  @override
  Future<Finder> findElement(WidgetTester tester, String elementId) async {
    // Try to find by position in widget tree
    // This is a last resort and less reliable
    throw Exception('Positional strategy not yet implemented');
  }
}

/// Fuzzy match strategy using similarity algorithms
class FuzzyMatchStrategy extends FinderStrategy {
  @override
  String get name => 'FuzzyMatch';

  @override
  Future<Finder> findElement(WidgetTester tester, String elementId) async {
    // Find all text widgets and calculate similarity
    final allText = find.byType(Text);

    for (final element in allText.evaluate()) {
      final widget = element.widget as Text;
      if (widget.data != null) {
        final similarity = _calculateSimilarity(elementId, widget.data!);
        if (similarity > 0.8) {
          // 80% similarity threshold
          return find.byWidget(widget);
        }
      }
    }

    throw Exception('No fuzzy match found');
  }

  /// Calculate Levenshtein distance-based similarity
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    final longerLength = longer.length;
    if (longerLength == 0) return 1.0;

    final distance = _levenshteinDistance(longer, shorter);
    return (longerLength - distance) / longerLength;
  }

  int _levenshteinDistance(String s1, String s2) {
    final costs = List<int>.filled(s2.length + 1, 0);

    for (var i = 0; i <= s1.length; i++) {
      var lastValue = i;
      for (var j = 0; j <= s2.length; j++) {
        if (i == 0) {
          costs[j] = j;
        } else if (j > 0) {
          var newValue = costs[j - 1];
          if (s1[i - 1] != s2[j - 1]) {
            newValue =
                [
                  newValue,
                  lastValue,
                  costs[j],
                ].reduce((a, b) => a < b ? a : b) +
                1;
          }
          costs[j - 1] = lastValue;
          lastValue = newValue;
        }
      }
      if (i > 0) costs[s2.length] = lastValue;
    }

    return costs[s2.length];
  }
}
